{ config, pkgs, ... }:
{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;

    environment = {
      ENABLE_OLLAMA_API = "false";
      OPENAI_API_BASE_URL = "https://openrouter.ai/api/v1";
      WEBUI_AUTH = "false";
    };
  };
}
