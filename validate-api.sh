#!/bin/bash
PROJECT_PATH=$1
ERRORS=0

echo "🔎 Validando governança de APIs em $PROJECT_PATH..."

# 1️⃣ Validar se todas as rotas possuem versionamento (/v1/, /v2/)
ROUTES=$(grep -r 'Route("' $PROJECT_PATH | awk -F'"' '{print $2}')
for ROUTE in $ROUTES; do
  if [[ ! $ROUTE =~ /v[0-9]+/ ]]; then
    echo "❌ Erro: A rota '$ROUTE' não possui versionamento explícito (ex: /v1/)."
    ERRORS=$((ERRORS+1))
  fi
done

# 2️⃣ Validar kebab-case nas rotas
for ROUTE in $ROUTES; do
  if [[ $ROUTE =~ [A-Z] ]]; then
    echo "❌ Erro: A rota '$ROUTE' não está em kebab-case."
    ERRORS=$((ERRORS+1))
  fi
done

# 3️⃣ Verificar se existe um arquivo `swagger.json` (opcional)
if [ ! -f "$PROJECT_PATH/swagger.json" ]; then
  echo "⚠️ Aviso: O arquivo 'swagger.json' não foi encontrado. Certifique-se de expor o OpenAPI."
fi

# Finalizar com erro se houverem falhas
if [ $ERRORS -gt 0 ]; then
  echo "⛔ Validação falhou com $ERRORS erros."
  exit 1
else
  echo "✅ Validação concluída sem erros."
fi
