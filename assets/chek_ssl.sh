#!/bin/bash

# Define the file paths
KEY_FILE="/etc/ssl/private/myserver.key"
CERT_FILE="/etc/ssl/certs/myserver.crt"
APACHE_SSL_CONF="/etc/apache2/sites-available/default-ssl.conf"
REPORT_FILE="report.json"

# Variables for the report
report=()

# Function to check the existence of files
check_files() {
    if [[ ! -f "$KEY_FILE" ]]; then
        report+=("{\"step\": \"check_files\", \"result\": \"failure\", \"message\": \"Clave privada no encontrada en $KEY_FILE\"}")
        return 1
    fi

    if [[ ! -f "$CERT_FILE" ]]; then
        report+=("{\"step\": \"check_files\", \"result\": \"failure\", \"message\": \"Certificado no encontrado en $CERT_FILE\"}")
        return 1
    fi

    report+=("{\"step\": \"check_files\", \"result\": \"success\", \"message\": \"Archivos de clave privada y certificado encontrados.\"}")
    return 0
}

# Function to check the validity of the certificate
check_certificate() {
    openssl x509 -in "$CERT_FILE" -noout -text > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        report+=("{\"step\": \"check_certificate\", \"result\": \"failure\", \"message\": \"El certificado en $CERT_FILE no es válido.\"}")
        return 1
    fi

    report+=("{\"step\": \"check_certificate\", \"result\": \"success\", \"message\": \"El certificado es válido.\"}")
    return 0
}

# Function to check the Apache SSL configuration
check_apache_config() {
    if grep -q "SSLEngine on" "$APACHE_SSL_CONF" && \
       grep -q "SSLCertificateFile $CERT_FILE" "$APACHE_SSL_CONF" && \
       grep -q "SSLCertificateKeyFile $KEY_FILE" "$APACHE_SSL_CONF"; then
        report+=("{\"step\": \"check_apache_config\", \"result\": \"success\", \"message\": \"La configuración de Apache SSL es correcta.\"}")
        return 0
    else
        report+=("{\"step\": \"check_apache_config\", \"result\": \"failure\", \"message\": \"La configuración de Apache SSL no es correcta.\"}")
        return 1
    fi
}


# Execute the verification functions
check_files
check_files_result=$?

check_certificate
check_certificate_result=$?

check_apache_config
check_apache_config_result=$?


# Generate the JSON report
echo "[" > $REPORT_FILE
for i in "${!report[@]}"; do
    echo "  ${report[$i]}" >> $REPORT_FILE
    if [[ $i -lt $(( ${#report[@]} - 1 )) ]]; then
        echo "," >> $REPORT_FILE
    fi
done
echo "]" >> $REPORT_FILE

# Show the overall result
if [[ $check_files_result -eq 0 && $check_certificate_result -eq 0 && $check_apache_config_result -eq 0 ]]; then
    echo "La configuración SSL con OpenSSL ha sido verificada correctamente."
else
    echo "Hubo errores en la verificación de la configuración SSL con OpenSSL. Revisa el reporte en $REPORT_FILE para más detalles."
fi
