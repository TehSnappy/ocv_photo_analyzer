defmodule OcvPhotoAnalyzer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ocv_photo_analyzer,
      version: "1.0.1",
      elixir: "~> 1.5",
      name: "ocv_photo_analyzer",
      description: description(),
      package: package(),
      source_url: "https://github.com/teh_snappy/ocv_photo_analyzer",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Elixir wrapper for generating histograms and finding dominant colors in images using OpenCV.
    """
  end

  defp package do
    %{
      files: ["src/*", "lib/*", "priv/*", "mix.exs", "README.md", "Makefile"],
      maintainers: ["Steven Fuchs"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/teh_snappy/ocv_photo_analyzer"}
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:porcelain, "~> 2.0"},
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.13", only: :dev, runtime: false}
    ]
  end
end
