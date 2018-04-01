defmodule OcvPhotoAnalyzer.Analyzer do
  @moduledoc false

  alias Porcelain.Result

  require Logger

  def analyze_file(file_path, opts, overrides) do
    proc_params = convert_params(opts, overrides) ++ [file_path]

    case Porcelain.exec(executable_path(), proc_params, out: :iodata, async_in: true) do
      %Result{err: nil, out: [_, data], status: 0} ->
        data |> strip_length_int |> :erlang.binary_to_term()

      %Result{err: err, status: status} ->
        Logger.error("received exec error #{err} status: #{status}")
        %{err: :exec_error}

      _ ->
        %{err: :unknown}
    end
  end

  defp strip_length_int(<<_lng::size(16), data::binary>>) do
    data
  end

  defp executable_path do
    (:code.priv_dir(:ocv_photo_analyzer) ++ '/analyzer') |> List.to_string()
  end

  defp convert_params(opts, overrides) do
    (opts ++ Enum.map(params(overrides), fn {k, v} -> [k, v] end))
    |> Enum.map(fn a ->
      case a do
        :dominant -> "-d"
        :histogram -> "-h"
        [:clusters, c] -> "-c #{c}"
        [:iterations, i] -> "-i #{i}"
        [:precision, p] -> "-p #{p}"
        [:attempts, a] -> "-a #{a}"
        [:analysis_size, r] -> "-r #{r}"
        _ -> ""
      end
    end)
  end

  defp params(overrides) do
    default_params()
    |> Map.merge(user_params_map())
    |> Map.merge(overrides)
  end

  defp user_params_map do
    Enum.into(Application.get_env(:ocv_photo_analyzer, OcvPhotoAnalyzer.Analyzer, []), %{})
  end

  defp default_params() do
    %{
      clusters: 5,
      iterations: 10,
      precision: 0.1,
      attempts: 5,
      analysis_size: 1000
    }
  end
end
