maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Sets up sources for Ubuntu Linux"
version           "1.0.0"
depends           "apt"
supports          "ubuntu"
recipe            "ubuntu", "Sets up sources for the node's Ubuntu release"