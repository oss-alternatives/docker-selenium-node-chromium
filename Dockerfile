# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM selenium/node-chrome

USER root

RUN set -o errexit -o nounset; \
    chrome_version="$(google-chrome --version | awk '{print $NF}')"; \
    sed -i 's|"/opt[^"]\+"|/opt/chromium/chrome|g' /usr/bin/google-chrome; \
    mv /usr/bin/google-chrome /usr/bin/chromium; \
    rm -r /opt/google /usr/bin/google*; \
    base_position="$(curl -fs "https://omahaproxy.appspot.com/deps.json?version=${chrome_version}" | \
            jq -r .chromium_base_position)"; \
    chrome_dir=chrome-linux; \
    chrome_zip="${chrome_dir}.zip"; \
    dest=/opt/chromium; \
    download_url() { \
        echo "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F${1}%2Fchrome-linux.zip?alt=media"; \
    }; \
    until curl -fI "$(download_url "$base_position")"; do \
        base_position=$(( base_position - 1 )); \
    done; \
    curl --compressed -fso "$chrome_zip" "$(download_url "$base_position")"; \
    unzip "$chrome_zip"; \
    rm "$chrome_zip"; \
    mkdir "$dest"; \
    mv "${chrome_dir}/"* "$dest"; \
    rmdir "${chrome_dir}"; \
    find /opt/bin -maxdepth 1 -type f -exec sed -i s/google-chrome/chromium/g {} +; \
    chromium_version="$(chromium --version | awk '{print $NF}')"; \
    sed -i "s/^CHROME_VERSION=.*/CHROME_VERSION=${chromium_version}/" /opt/bin/generate_config; \
    echo Got Chromium "$(chromium --version | awk '{print $2}')"

USER seluser
