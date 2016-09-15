curl -k -X POST -H "Content-Type: application/json" \
-d '{ "setup": {
    "decryption_passphrase": "example-passphrase",
    "decryption_passphrase_confirmation":"example-passphrase",
    "eula_accepted": "true",
    "identity_provider": "internal",
    "admin_user_name": "admin",
    "admin_password": "example-password",
    "admin_password_confirmation": "example-password"
  } }' \
"https://$1/api/v0/setup"
