install-cocoapods:
	rm -rf vendor
	bundler install --path vendor/bundle

pod-install:
	bundle exe pod install --repo-update

install: install-cocoapods pod-install
