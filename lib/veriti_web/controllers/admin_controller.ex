defmodule VeritiWeb.AdminController do
  use VeritiWeb, :controller

  alias Veriti.Admin

  def export_csv(conn, params) do
    filters = Map.take(params, ["status", "date_range"])
    submissions = Admin.list_submissions(filters)
    csv = build_csv(submissions)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s[attachment; filename="submissions.csv"])
    |> send_resp(200, csv)
  end

  defp build_csv(submissions) do
    headers = [
      "ID", "User Email", "Filename", "Content Type", "Submission Status",
      "VIN", "Title Number", "State", "Owner", "Odometer",
      "Validation Status", "Issues", "Submitted At"
    ]

    rows =
      Enum.map(submissions, fn sub ->
        r = sub.validation_result

        [
          sub.id,
          sub.user.email,
          sub.original_filename,
          sub.content_type,
          sub.status,
          r && r.extracted_vin,
          r && r.extracted_title_number,
          r && r.extracted_state,
          r && r.extracted_owner,
          r && r.extracted_odometer,
          r && r.overall_status,
          r && Enum.join(r.issues || [], " | "),
          Calendar.strftime(sub.inserted_at, "%Y-%m-%d %H:%M:%S UTC")
        ]
      end)

    [headers | rows]
    |> Enum.map_join("\n", &csv_row/1)
  end

  defp csv_row(fields), do: Enum.map_join(fields, ",", &csv_field/1)

  defp csv_field(nil), do: ""

  defp csv_field(val) do
    str = to_string(val)

    if String.contains?(str, [",", "\"", "\n", "\r"]) do
      ~s["#{String.replace(str, "\"", "\"\"")}"]
    else
      str
    end
  end
end
