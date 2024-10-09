data "http" "cloudflare_ips" {
  url = "https://api.cloudflare.com/client/v4/ips"
}

locals {
  cloudflare_ipv4_cidrs = jsondecode(data.http.cloudflare_ips.response_body).result.ipv4_cidrs
  cloudflare_ipv6_cidrs = jsondecode(data.http.cloudflare_ips.response_body).result.ipv6_cidrs
}
