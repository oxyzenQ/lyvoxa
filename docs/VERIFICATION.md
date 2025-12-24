# Verification

Verify release artifacts before installing.

## Artifacts

Every release includes:

- `lyvoxa-${VERSION}-linux-amd64.tar.gz`
- `lyvoxa-${VERSION}-linux-amd64.tar.gz.sha256`

If the maintainer enabled signing in CI, releases may also include:

- `lyvoxa-${VERSION}-linux-amd64.tar.gz.sig` (binary detached signature)
- `lyvoxa-${VERSION}-linux-amd64.tar.gz.asc` (ASCII-armored detached signature)
- `lyvoxa-${VERSION}-linux-amd64.tar.gz.sha256.asc` (signed checksum)

## Download

```bash
VERSION="3.1.0"
BASE_URL="https://github.com/oxyzenQ/lyvoxa/releases/download/${VERSION}"
ARTIFACT="lyvoxa-${VERSION}-linux-amd64"

wget -q "${BASE_URL}/${ARTIFACT}.tar.gz"
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz.sha256"
```

## SHA256 (required)

```bash
sha256sum -c "${ARTIFACT}.tar.gz.sha256"
```

Only proceed if it prints `OK`.

## GPG (optional)

Import the maintainer public key once:

```bash
gpg --keyserver hkps://keys.openpgp.org --recv-keys 0D8D13BB989AF9F0
```

Verify the signature if the release provides it:

```bash
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz.asc" || true
wget -q "${BASE_URL}/${ARTIFACT}.tar.gz.sig" || true

if [ -f "${ARTIFACT}.tar.gz.asc" ]; then
  gpg --verify "${ARTIFACT}.tar.gz.asc" "${ARTIFACT}.tar.gz"
elif [ -f "${ARTIFACT}.tar.gz.sig" ]; then
  gpg --verify "${ARTIFACT}.tar.gz.sig" "${ARTIFACT}.tar.gz"
fi
```

Notes:

- A `Good signature` message indicates authenticity.
- A `not certified with a trusted signature` warning is common for keys you have not explicitly trusted.
