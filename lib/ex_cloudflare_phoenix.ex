defmodule ExCloudflarePhoenix do

  @doc """
    Provides configuration values from the application env.
    """
  @spec config(atom()) :: String.t() | nil
  def config(key) do
    case key do
      :app_id -> ExCloudflareCore.Config.app_id()
      :secret -> ExCloudflareCore.Config.app_secret()
      _ -> nil
    end
  end

end
