
#include "opencv2/highgui.hpp"
#include "opencv2/imgcodecs.hpp"
#include "opencv2/imgproc.hpp"
#include <iostream>
#include <ei.h>
#include <poll.h>
#include <err.h>
#include <inttypes.h>
#include <signal.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/select.h>

using namespace std;
using namespace cv;

int clusters = 5;
int attempts = 5;
int iterations = 10;
int analysis_size = 1000.0;
float precision = 0.1;
bool do_histogram = false;
bool do_dominant = false;

void erlcmd_send(char *response, size_t len)
{
    uint16_t be_len = htons(len - sizeof(uint16_t));
    memcpy(response, &be_len, sizeof(be_len));

    size_t wrote = 0;
    do {
        ssize_t amount_written = write(STDOUT_FILENO, response + wrote, len - wrote);
        if (amount_written < 0) {
          if (errno == EINTR)
            continue;
          exit(0);
        }

        wrote += amount_written;
    } while (wrote < len);
}

void send_histogram(char* resp, int* resp_index, long* reds, long* greens, long* blues) {
    ei_encode_atom(resp, resp_index, "histogram");
    
    ei_encode_map_header(resp, resp_index, 3);
    ei_encode_atom(resp, resp_index, "r");

    ei_encode_list_header(resp, resp_index, 256);
    for( int i = 0; i < 256; i++ )
      ei_encode_long(resp, resp_index, reds[i]);
    ei_encode_empty_list(resp, resp_index);

    ei_encode_atom(resp, resp_index, "g");
    ei_encode_list_header(resp, resp_index, 256);
    for( int i = 0; i < 256; i++ )
      ei_encode_long(resp, resp_index, greens[i]);
    ei_encode_empty_list(resp, resp_index);

    ei_encode_atom(resp, resp_index, "b");
    ei_encode_list_header(resp, resp_index, 256);
    for( int i = 0; i < 256; i++ )
      ei_encode_long(resp, resp_index, blues[i]);
    ei_encode_empty_list(resp, resp_index);
}

void send_dominant(char* resp, int* resp_index, Mat centers) {
    ei_encode_atom(resp, resp_index, "dominant");
    
    ei_encode_list_header(resp, resp_index, clusters);
    
    for( int z = 0; z < clusters; z++) {
      ei_encode_map_header(resp, resp_index, 3);
      ei_encode_atom(resp, resp_index, "r");
      ei_encode_long(resp, resp_index, centers.at<float>(z, 2) * 1);
      ei_encode_atom(resp, resp_index, "g");
      ei_encode_long(resp, resp_index, centers.at<float>(z, 1) * 1);
      ei_encode_atom(resp, resp_index, "b");
      ei_encode_long(resp, resp_index, centers.at<float>(z, 0) * 1);
    }
    ei_encode_empty_list(resp, resp_index);
}

void send_error(const char *message) {
  char resp[2048];
  
  int resp_index = sizeof(uint16_t); // Space for payload size

  ei_encode_version(resp, &resp_index);
  ei_encode_tuple_header(resp, &resp_index, 2);
  ei_encode_atom(resp, &resp_index, "error");
  ei_encode_binary(resp, &resp_index, message, strlen(message));

  erlcmd_send(resp, resp_index);
}

void get_dominant(Mat src, char* resp, int* respIndex) {
  Mat dst;

  float ratio = fmin(1.0, analysis_size / fmax(src.rows, src.cols));

  resize(src, dst, Size(), ratio, ratio, INTER_AREA);

  Mat samples(dst.rows * dst.cols, 3, CV_32F);
  for( int y = 0; y < dst.rows; y++ )
    for( int x = 0; x < dst.cols; x++ )
      for( int z = 0; z < 3; z++)
        samples.at<float>(y + x*dst.rows, z) = dst.at<Vec3b>(y,x)[z];
  
  Mat labels;
  Mat centers;
  kmeans(samples, clusters, labels, TermCriteria(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS, iterations, precision), attempts, KMEANS_PP_CENTERS, centers );

  send_dominant(resp, respIndex, centers);
}

void make_histogram(Mat src, char* resp, int* respIndex) {
  vector<Mat> bgr_planes;
  split(src, bgr_planes);

  int histSize = 256;

  float range[] = { 0, 256 } ;
  const float* histRange = { range };

  bool uniform = true; bool accumulate = false;

  Mat b_hist, g_hist, r_hist;

  calcHist( &bgr_planes[0], 1, 0, Mat(), b_hist, 1, &histSize, &histRange, uniform, accumulate );
  calcHist( &bgr_planes[1], 1, 0, Mat(), g_hist, 1, &histSize, &histRange, uniform, accumulate );
  calcHist( &bgr_planes[2], 1, 0, Mat(), r_hist, 1, &histSize, &histRange, uniform, accumulate );

  normalize(b_hist, b_hist, 0, 256, NORM_MINMAX, -1, Mat() );
  normalize(g_hist, g_hist, 0, 256, NORM_MINMAX, -1, Mat() );
  normalize(r_hist, r_hist, 0, 256, NORM_MINMAX, -1, Mat() );

  long hldr_r[256];
  long hldr_g[256];
  long hldr_b[256];
  
  for( int i = 0; i < histSize; i++ ) {
    hldr_r[i] = (long)cvRound(r_hist.at<float>(i));
    hldr_g[i] = (long)cvRound(g_hist.at<float>(i));
    hldr_b[i] = (long)cvRound(b_hist.at<float>(i));
  }

  send_histogram(resp, respIndex, hldr_r, hldr_g, hldr_b);
}

void do_analyze(char *file_name) {
  String imageName( (const char*)file_name );
  Mat src;

  src = imread(imageName, IMREAD_COLOR);

  if(src.empty()) {
    send_error("not_found");
  } else {
    int cnt = 0;
    if (do_dominant)
      cnt++;
    if (do_histogram)
      cnt++;

    if (cnt > 0) {
      char resp[2048];
      int resp_index = sizeof(uint16_t);

      ei_encode_version(resp, &resp_index);
      ei_encode_map_header(resp, &resp_index, cnt);

      if (do_dominant)
        get_dominant(src, resp, &resp_index); 
      if (do_histogram)
        make_histogram(src, resp, &resp_index);   

      erlcmd_send(resp, resp_index);
    } else {
      send_error("empty request");
    }
  }
}

int main(int argc, char** argv)
{
    int mode = 0, opt;
    bool isCaseInsensitive = false;

    while ((opt = getopt(argc, argv, "r:c:i:a:p:dh")) != -1) {
      switch (opt) {
      case 'c': clusters = atoi(optarg); break;
      case 'i': iterations = atoi(optarg); break;
      case 'a': attempts = atoi(optarg); break;
      case 'p': precision = atof(optarg); break;
      case 'r': analysis_size = atof(optarg); break;
      case 'd': do_dominant = true; break;
      case 'h': do_histogram = true; break;
      default:
          fprintf(stderr, "Usage: %s [-criapdh] [file...]\n", argv[0]);
          exit(EXIT_FAILURE);
      }
  }

  do_analyze(argv[argc - 1]);

  exit(EXIT_SUCCESS);
}
