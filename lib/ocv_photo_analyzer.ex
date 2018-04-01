defmodule OcvPhotoAnalyzer do
  @moduledoc """
  OcvPhotoAnalyzer provides access to histograms and color clustering analysis of photos to elixir through OpenCV. 

  Color clustering can take a long time depending on the image and the parameters passed to the clustering algorithm. For this reason the analysis_size parameter has been added to the configs. Prior to performing the clustering analysis the image will be resized to a maximum dimension of analysis_size. This can greatly speed with analysis without affecting the results too much.

  The histogram is always caluclated from the full size image.

  These settings can be set in the configuration for your app. The default settings, which are listed below, will be applied in the absence of a config.

  ```
  config :ocv_photo_analyzer, OcvPhotoAnalyzer.Analyzer,
    clusters: 5,
    iterations: 10,
    attempts: 5,
    precision: 0.1,
    analysis_size: 1000.0
    
  ```

  These values (other than analysis_size) are passed directly to the OpenCV ```kmeans``` function which is explained in some detail in [the OpenCV docs here](https://docs.opencv.org/2.4/modules/core/doc/clustering.html).

  """

  @doc """
  Analyze the image passed in image_path. 

  `OcvPhotoAnalyzer.Analyzer.analyze` takes three parameters, the absolute file path, an array of options, and a map of config overrides.

  If no options are provided, all analyses will be run (histogram and dominant).

  The overrides parameter lets any of the values passed in the config be superseded for that run only. In their absense the default values, or the values stored in the config are used.

  It returns a Map in the following format. Note that the :histogram and :dominant keys will only be present if that analysis was requested.
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


  """
  def analyze(image_path, opts \\ [:histogram, :dominant], overrides \\ %{}) do
    OcvPhotoAnalyzer.Analyzer.analyze_file(image_path, opts, overrides)
  end

  @doc false
  def start(_type, _args) do
    OcvPhotoAnalyzer.Supervisor.start_link()
  end
end
