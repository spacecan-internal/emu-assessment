$api_token = ""
$base_url = "https://gitlab.com/api/v4/"
$group_name = "serralagroup"
$page = 1
$per_page = 99
$suffix = "groups/$group_name/projects?include_subgroups=true&all_available=true&per_page=$per_page&page=$page"
$url = "$base_url$suffix"

# Make a request to the GitLab API and get the list of project names
$response = Invoke-RestMethod -Uri $url -Headers @{ "PRIVATE-TOKEN" = $api_token } -ResponseHeadersVariable headers

# Extract the total number of pages from the x-total-pages header
$total_pages = [int]$headers.'x-total-pages'[0]

# Write the total number of pages
Write-Host "Total pages: $total_pages"

# Loop through all pages and get the project "name", "name_with_namespace", "_links.self" properties, and check for CI/CD usage

$projects = @()
for ($i = 1; $i -le $total_pages; $i++) {
  Write-Host "Starting job for page $i of $total_pages"
  $url = "$base_url$($suffix.Replace("page=$page","page=$i"))"
  $response = Invoke-RestMethod -Uri $url -Headers @{ "PRIVATE-TOKEN" = $api_token }

  # $projects += $response | Select-Object name, name_with_namespace, @{Name="_links.self";Expression={$_.web_url}}

  foreach ($project in $response) {
    $project_name = $project.name
    $project_namespace = $project.name_with_namespace
    $project_self_link = $project.web_url

    # Check if the project uses CI/CD by looking for the .gitlab-ci.yml file
    $ci_cd_url = "$base_url/projects/$($project.id)/repository/files/.gitlab-ci.yml?ref=master"
    try {
      $ci_cd_response = Invoke-RestMethod -Uri $ci_cd_url -Headers @{ "PRIVATE-TOKEN" = $api_token }
      $ci_cd_status = "Yes"
    }
    catch {
      $ci_cd_status = "No"
    }

    $projects += [PSCustomObject]@{
      Name              = $project_name
      NameWithNamespace = $project_namespace
      SelfLink          = $project_self_link
      UsesCI_CD         = $ci_cd_status
    }
  }
}

# Export the projects to a CSV file
$projects | Export-Csv -Path "gitlab-projects-ci-cd.csv" -NoTypeInformation
