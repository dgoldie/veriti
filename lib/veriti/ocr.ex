defmodule Veriti.OCR do
  @doc """
  Extracts text from an uploaded title document.
  Returns {:ok, text} for images, {:error, reason} for unsupported types or failures.
  """
  def extract_text(file_path, content_type) do
    cond do
      String.starts_with?(content_type, "image/") ->
        text = TesseractOcr.read(file_path)
        {:ok, text}

      content_type == "application/pdf" ->
        {:error, :pdf_not_supported}

      true ->
        {:error, :unsupported_content_type}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
