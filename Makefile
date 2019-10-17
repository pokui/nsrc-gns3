.PHONY: apt-depends
apt-depends:
	sudo apt-get install -y cloud-image-utils yamllint zip unzip libguestfs-tools

.PHONY: docs
docs:
	find . -name '*~' -delete
	mkdocs build
