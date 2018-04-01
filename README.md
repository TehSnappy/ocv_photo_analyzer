# OcvPhotoAnalyzer

OcvPhotoAnalyzer provides access to histograms and color clustering analysis of photos to elixir through OpenCV. 

## Installation

The package can be installed by adding `ocv_photo_analyzer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ocv_photo_analyzer, "~> 1.0.0"}
  ]
end
```

## Usage
  There is only one public function in this package at present:

  ```OcvPhotoAnalyzer.analyze(absolute_file_path)```

  In this case both analyses would be run on the file. If you don't want to run both you can narrow that down.

  ```OcvPhotoAnalyzer.analyze(absolute_file_path, [:histogram])```

  If you'd like to run the color clustering with different parameters than the default, or the values you provide in the config, you can do that also.

  ```OcvPhotoAnalyzer.analyze(absolute_file_path, [:dominant], %{clusters: 3})```


## Notes
  Histogram generation is usually pretty fast.

  Color clustering can take a long time depending on the image and the parameters passed to the clustering algorithm. For this reason the analysis_size parameter has been added to the configs. Prior to performing the clustering analysis the image will be resized to where its largest maximum dimension is the value in analysis_size. This can greatly speed with analysis without affecting the results too much.

  The histogram is always calculated from the full size image.

  These settings can be set in the configuration for your app. The default settings, which are listed below, will be applied in the absence of a config.

```
  config :ocv_photo_analyzer, OcvPhotoAnalyzer.Analyzer,
    clusters: 5,
    iterations: 10,
    attempts: 5,
    precision: 0.1,
    analysis_size: 1000

```

  These values (other than analysis_size) are passed directly to the OpenCV ```kmeans``` function which is explained in some detail in [the OpenCV docs here](https://docs.opencv.org/2.4/modules/core/doc/clustering.html).

  All parameters in the config can be overridden by passing them as a map in the overrrides param.

## Returned Values
  It returns a Map in the following format. Note that the :histogram and :dominant keys will only be present if that analysis was performed.

```
    %{
        histogram: %{
          r: [0, 10, 31, 3, ..., 20, 76],
          g: [0, 20, 55, 5, ..., 24, 4],
          b: [0, 11, 3, 55, ..., 40, 7]
        },
        dominant: [
          %{
            r: 12,
            g: 200,
            b: 120
          },
          %{
            r: 124,
            g: 20,
            b: 12
          },
          %{
            r: 52,
            g: 50,
            b: 20
          }
        ]
    }
```





