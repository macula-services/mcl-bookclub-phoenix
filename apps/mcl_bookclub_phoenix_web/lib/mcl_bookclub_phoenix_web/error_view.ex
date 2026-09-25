defmodule MclBookclubPhoenixWeb.ErrorView do
  # Phoenix falls back to this module by naming convention when no
  # :render_errors is configured -- that default ships accepts: ~w(html)
  # and layout: false, so this only ever needs an html clause and gets no
  # root layout around it. Without this module any unmatched route (a bad
  # path, a stray favicon request) crashed to a raw 500 instead of a clean
  # 404/500 page.

  def render("404.html", _assigns), do: page("Nothing here", "This page doesn't exist.")

  def render("500.html", _assigns),
    do: page("Something broke", "The host hit an error. Try reloading.")

  def render(template, _assigns) do
    status = template |> String.split(".") |> List.first()
    page("Error #{status}", "Something went wrong.")
  end

  # {:safe, iodata} tells Phoenix.HTML this is already-rendered markup --
  # a plain string return here gets html-escaped whole.
  defp page(title, message), do: {:safe, page_html(title, message)}

  defp page_html(title, message) do
    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{title} · mcl-bookclub</title>
        <style>
          :root {
            --ink: #1a1d21; --muted: #6b7280; --paper: #faf9f7;
            --accent: #b45309;
          }
          html, body {
            height: 100%;
            margin: 0;
            background: var(--paper);
            color: var(--ink);
            font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
            -webkit-font-smoothing: antialiased;
          }
          body {
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .card {
            text-align: center;
            max-width: 28rem;
            padding: 2rem;
          }
          h1 {
            font-size: 1.25rem;
            font-weight: 600;
            margin: 0 0 0.5rem;
          }
          p {
            color: var(--muted);
            margin: 0 0 1.5rem;
          }
          a {
            display: inline-block;
            color: #fff;
            background: var(--accent);
            text-decoration: none;
            font-size: 0.85rem;
            font-weight: 600;
            padding: 0.5rem 1rem;
            border-radius: 8px;
          }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>#{title}</h1>
          <p>#{message}</p>
          <a href="/">Back to the admin</a>
        </div>
      </body>
    </html>
    """
  end
end
