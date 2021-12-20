#  scripts/bootstrap.sh
#
#  What It Does
#  ------------
#  - Runs carthage, recaptcha integration, generates the project and opens it.
# 

set -ue

if [ ! -f ".env" ]; then
	echo "renaming .env.default to .env"
	cp .env.default .env
fi

echo "Running Carthage"
sh ./scripts/carthage.sh bootstrap --use-ssh --cache-builds --platform iOS --use-xcframeworks --no-use-binaries

echo "Running Recaptcha"
sh ./scripts/recaptcha.sh

echo "Generating project"
sh ./scripts/generate_projects.sh

echo "Resolve Package Dependencies"
xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath ./SourcePackages -packageCachePath ${PWD}/PackageCache -disableAutomaticPackageResolution

echo "Install Mockingbird"
sh ./scripts/install-mockingbird.sh

echo "Install Mocks"
sh ./scripts/install-mocks.sh

echo "Opening project"
open Blockchain.xcodeproj
