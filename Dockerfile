FROM debian:trixie-slim@sha256:7378260c0a098d27ac206225db5e7d92b8c7c84ea7afccc86eeb513756bbd392

ARG GODOT_VERSION=4.7.2
ARG GODOT_LINUX_SHA512=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65
ARG GODOT_TEMPLATES_SHA512=ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/venv/bin:${PATH}"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        libasound2 \
        libfontconfig1 \
        libgl1 \
        libpulse0 \
        libx11-6 \
        libxcursor1 \
        libxinerama1 \
        libxi6 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        python3 \
        python3-venv \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 dev \
    && useradd --create-home --gid dev --shell /bin/bash --uid 1000 dev \
    && python3 -m venv /opt/venv

RUN curl --fail --location --silent --show-error \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
        --output /tmp/godot.zip \
    && echo "${GODOT_LINUX_SHA512}  /tmp/godot.zip" | sha512sum --check --status \
    && unzip -q /tmp/godot.zip -d /tmp/godot \
    && install -m 0755 "/tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && rm -rf /tmp/godot /tmp/godot.zip

RUN mkdir -p "/home/dev/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
    && curl --fail --location --silent --show-error \
        "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
        --output /tmp/godot-templates.tpz \
    && echo "${GODOT_TEMPLATES_SHA512}  /tmp/godot-templates.tpz" | sha512sum --check --status \
    && unzip -q /tmp/godot-templates.tpz -d /tmp/godot-templates \
    && mv /tmp/godot-templates/templates/* "/home/dev/.local/share/godot/export_templates/${GODOT_VERSION}.stable/" \
    && rm -rf /tmp/godot-templates /tmp/godot-templates.tpz \
    && chown -R dev:dev /home/dev/.local

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --require-hashes -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

WORKDIR /workspace
USER dev

CMD ["sleep", "infinity"]
