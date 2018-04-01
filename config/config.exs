use Mix.Config

config :porcelain, :goon_driver_path, "~/bin/goon" |> Path.expand()

config :ocv_photo_analyzer, OcvPhotoAnalyzer.Analyzer,
  clusters: 5,
  iterations: 10,
  attempts: 5,
  precision: 0.1,
  analysis_size: 1000
