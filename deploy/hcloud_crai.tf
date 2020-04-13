provider "hcloud" {
}

resource "hcloud_ssh_key" "hcloud_crai_root" {
    name = "hcloud-crai-root"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILghH9+xrmJK340E3ppDC5ee5FNjNQ+0GqfGWx5sPTaC r@chloe-notebook"
}

resource "hcloud_server" "hcloud_crai" {
    name = "hcloud-crai"
    image = "debian-10"
    location = "nbg1"
    server_type = "cx11"
    ssh_keys = [ hcloud_ssh_key.hcloud_crai_root.name ]
}

output "hcloud_crai_ipv4" {
    value = hcloud_server.hcloud_crai.ipv4_address
}
