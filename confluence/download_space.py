import os
import requests

def download_space_as_pdf(base_url, space_key, api_token):
    # Set up the API endpoint
    api_endpoint = f"{base_url}/wiki/rest/api/space/{space_key}/export/pdf"

    # Prepare the headers with the API token
    headers = {
        "Authorization": f"Basic {api_token}",
    }

    # Make the API request to initiate the export
    response = requests.post(api_endpoint, headers=headers)

    if response.status_code == 200:
        # Parse the response to get the export ID
        export_id = response.json().get("id")
        print(f"Export initiated. Export ID: {export_id}")

        # Wait for the export to be ready
        while True:
            status_endpoint = f"{base_url}/wiki/rest/api/export/{export_id}"
            response = requests.get(status_endpoint, headers=headers)

            if response.status_code == 200:
                status = response.json().get("status")

                if status == "finished":
                    # Download the exported PDF file
                    download_url = f"{base_url}/wiki/spaces/{space_key}/export-pdf?pageId={export_id}"
                    response = requests.get(download_url, headers=headers, stream=True)

                    if response.status_code == 200:
                        filename = f"{space_key}_export.pdf"

                        # Save the file to the current directory
                        with open(filename, "wb") as f:
                            for chunk in response.iter_content(chunk_size=8192):
                                f.write(chunk)

                        print(f"Space downloaded and saved as '{filename}'.")
                    else:
                        print("Failed to download the space.")
                    break

                elif status == "exporting":
                    print("Export in progress...")
                else:
                    print("Export failed.")
                    break

            else:
                print("Failed to get export status.")
                break

    else:
        print("Failed to initiate the export.")

if __name__ == "__main__":
    # Replace these values with your Confluence information
    base_url = "YOUR_CONFLUENCE_BASE_URL"
    space_key = "YOUR_SPACE_KEY"
    api_token = "YOUR_API_TOKEN"

    download_space_as_pdf(base_url, space_key, api_token)

