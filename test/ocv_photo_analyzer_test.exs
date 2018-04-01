defmodule OcvPhotoAnalyzerTest do
  use ExUnit.Case
  use Mix.Config

  doctest OcvPhotoAnalyzer

  test "returns an error if image missing" do
    assert OcvPhotoAnalyzer.analyze(full_path("foo.jpg"), []) == {:error, "not_found"}
  end

  test "runs histogram and dominant if no opts are given" do
    data = OcvPhotoAnalyzer.analyze(full_path("test_histo.png"))

    assert(Map.has_key?(data, :histogram))
    assert(Map.has_key?(data, :dominant))
  end

  test "creates an image histogram" do
    data = OcvPhotoAnalyzer.analyze(full_path("test_histo.png"), [:histogram])

    check_histogram(data[:histogram][:r])
    check_histogram(data[:histogram][:g])
    check_histogram(data[:histogram][:b])
  end

  test "analyzes an image for dominant colors" do
    data = OcvPhotoAnalyzer.analyze(full_path("test_dominant.png"), [:dominant])

    assert(data[:dominant] |> Enum.fetch!(0) |> Map.equal?(%{b: 0, g: 0, r: 255}))
    assert(data[:dominant] |> Enum.fetch!(1) |> Map.equal?(%{b: 255, g: 255, r: 255}))
  end

  test "default config returns 5 colors" do
    data = OcvPhotoAnalyzer.analyze(full_path("test_dominant.png"), [:dominant])

    assert(data[:dominant] |> Enum.count() == 5)
  end

  test "clusters can be overridden to 3" do
    data = OcvPhotoAnalyzer.analyze(full_path("test_dominant.png"), [:dominant], %{clusters: 3})

    assert(data[:dominant] |> Enum.count() == 3)
  end

  defp full_path(fname) do
    :code.priv_dir(:ocv_photo_analyzer) |> Path.join(fname)
  end

  defp check_histogram(hg) do
    assert(Enum.count(hg) == 256)
    assert(Enum.at(hg, 4) != 0)
    assert(Enum.at(hg, 10) != 0)
    assert(Enum.at(hg, 119) != 0)
  end
end
