# Transcrypt pre-commit hook: fail if secret file in staging lacks the magic prefix "Salted" in B64
CRYPT_DIR=$(git config transcrypt.crypt-dir 2>/dev/null || printf '%s/crypt' "${GIT_COMMON_DIR}")
if [ -e "${CRYPT_DIR}/transcrypt" ]; then
    "${CRYPT_DIR}/transcrypt" pre_commit
fi
