variable "VERSION" {
    default = "dev"
}

variable "BUILD_ARM" {
    default = false
}

variable "LUNA_BRANCH" {
    default = "dev"
}

variable "LINA_BRANCH" {
    default = "dev"
}

variable "PUSH_ENABLED" {
    default = false
}

group "default" {
    targets = ["ce"]
}



target "lina" {
    context = "https://github.com/matheus-marques-ft/js-lina.git#${LINA_BRANCH}"
    dockerfile = "Dockerfile"
    tags = ["ghcr.io/matheus-marques-ft/lina:${VERSION}"]
    output = ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
}

target "luna" {
    dockerfile = "Dockerfile"
    context = "https://github.com/matheus-marques-ft/js-luna.git#${LUNA_BRANCH}"
    tags = ["ghcr.io/matheus-marques-ft/luna:${VERSION}"]
    output = ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
}


target "ce" {
    context = "."
    dockerfile = "Dockerfile"
    tags = [
        "ghcr.io/matheus-marques-ft/web:${VERSION}-ce",
        "ghcr.io/matheus-marques-ft/web:${VERSION}",
    ]
    output = PUSH_ENABLED ? ["type=registry"] : ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
    contexts = {
        "ghcr.io/matheus-marques-ft/lina:${VERSION}" = "target:lina"
        "ghcr.io/matheus-marques-ft/luna:${VERSION}" = "target:luna"
    }
    VERSION = "${VERSION}"
}