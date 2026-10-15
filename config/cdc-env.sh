# shellcheck shell=sh
# Installed to /etc/profile.d/. Dockerfile ENV values are image metadata and
# are dropped by `podman export`, so WSL sessions get them from here instead.

for _cdc_bundle in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
    if [ -r "$_cdc_bundle" ]; then
        # Python (requests/pip use certifi, not the OS store), curl, and Go
        export REQUESTS_CA_BUNDLE="$_cdc_bundle"
        export SSL_CERT_FILE="$_cdc_bundle"
        export PIP_CERT="$_cdc_bundle"
        export CURL_CA_BUNDLE="$_cdc_bundle"
        break
    fi
done
unset _cdc_bundle

# Node.js uses its bundled CA list unless told to use the OpenSSL store
case " ${NODE_OPTIONS:-} " in
    *" --use-openssl-ca "*) ;;
    *) export NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--use-openssl-ca" ;;
esac

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"
