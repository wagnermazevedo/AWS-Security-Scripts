#!/bin/bash

# ===================================================
# Configurações Globais
# ===================================================
AWS_REGION="us-east-1"
BASE_DIR="$HOME"
DEFAULT_REPO="Security-Control-Plane"

get_repo_description() {
    local repo_name="$1"
    case "$repo_name" in
        "Security-Control-Plane")
            echo "Plano de controle central para agregação, normatização e remediação geral de findings do Security Hub." ;;
        "AWS-Governance-as-Control-Plane")
            echo "Governança declarativa de postura, guardrails organizacionais e compliance contínuo." ;;
        "IAM-Identity-as-Control-Plane")
            echo "Controle de acesso, privilégios excessivos, gestão de credenciais e postura de identidades IAM." ;;
        "AWS-Network-Traffic-as-Control-Plane")
            echo "Inspeção e remediação de exposição de rede, Security Groups, VPCs e rotas de tráfego." ;;
        "Credential-Exposure-Control-Plane")
            echo "Detecção e resposta rápida para vazamento de chaves de acesso e credenciais expostas." ;;
        "PaaS-Managed-Services-Permissions-Control-Plane")
            echo "Segurança e permissões em serviços gerenciados (RDS, S3, DynamoDB, EKS, etc.)." ;;
        "Software-Defined-Perimeter-as-Control-Plane")
            echo "Gestão de perímetro definido por software, acesso zero-trust e regras de entrada/saída." ;;
        "AWS-Security-Scripts")
            echo "Coleção de utilitários e automações auxiliares para auditoria de segurança AWS." ;;
        *)
            echo "Módulo dinâmico de segurança e controle de postura em nuvem." ;;
    esac
}

anonimize_file() {
    local target_file="$1"
    if [ -f "$target_file" ]; then
        echo "   -> Anonimizando dados sensíveis em: $target_file"
        sed -i -E 's/[0-9]{12}/123456789012/g' "$target_file"
        sed -i -E 's/arn:aws:([a-zA-Cal-z0-9_-]+):([a-z0-9_-]+):123456789012:([^ \"]+)/arn:aws:\1:\2:123456789012:resource-masked/g' "$target_file"
        sed -i -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/user@masked-domain.local/g' "$target_file"
    fi
}

find_stage_script() {
    local repo_dir="$1"
    local stage="$2"
    local target_script=""
    
    target_script=$(ls -1 "$repo_dir"/scripts/${stage}_*.py 2>/dev/null | head -n 1)

    if [ -z "$target_script" ]; then
        case "$stage" in
            "00") target_script=$(ls -1 "$repo_dir"/scripts/*scan*.py 2>/dev/null | head -n 1) ;;
            "01") target_script=$(ls -1 "$repo_dir"/scripts/*plan*.py 2>/dev/null | head -n 1) ;;
            "02") target_script=$(ls -1 "$repo_dir"/scripts/*remediat*.py 2>/dev/null | head -n 1) ;;
        esac
    fi

    if [ -z "$target_script" ]; then
        target_script=$(ls -1 "$repo_dir"/${stage}_*.py 2>/dev/null | head -n 1)
    fi

    echo "$target_script"
}

find_rules_file() {
    local repo_dir="$1"
    local rules_file=""
    
    for possible_path in \
        "$repo_dir/config/remediate_map.yaml" \
        "$repo_dir/config/governance_rules.yaml" \
        "$repo_dir/config/rules.yaml" \
        "$repo_dir/scripts/remediate_map.yaml" \
        "$repo_dir/remediate_map.yaml" \
        "$repo_dir/config/"*.yaml \
        "$repo_dir/"*.yaml; do
        
        if [ -f "$possible_path" ] && [[ "$possible_path" != *"remediation_plan"* ]]; then
            rules_file="$possible_path"
            break
        fi
    done

    echo "$rules_file"
}

validate_repo_integrity() {
    local repo_dir="$1"
    local scan_s=$(find_stage_script "$repo_dir" "00")
    local plan_s=$(find_stage_script "$repo_dir" "01")
    local reme_s=$(find_stage_script "$repo_dir" "02")

    if [ -n "$scan_s" ] && [ -n "$plan_s" ] && [ -n "$reme_s" ]; then
        echo "INTEGRO"
    else
        local missing=""
        [ -z "$scan_s" ] && missing+="[SCAN (00)] "
        [ -z "$plan_s" ] && missing+="[PLAN (01)] "
        [ -z "$reme_s" ] && missing+="[REMEDIATE (02)] "
        echo "INCOMPLETO: Faltando $missing"
    fi
}

get_all_repos() {
    local found_repos=()
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            local folder_name=$(basename "$dir")
            if [[ "$folder_name" == .* ]]; then continue; fi
            if [ -d "$dir/.git" ] || [ -d "$dir/scripts" ]; then
                found_repos+=("${dir%/}")
            fi
        fi
    done
    echo "${found_repos[@]}"
}

run_list_repos() {
    echo "===================================================="
    echo " AWS Security Control Plane: REPOSITÓRIOS DISPONÍVEIS "
    echo "===================================================="
    local repos=($(get_all_repos))
    if [ ${#repos[@]} -eq 0 ]; then
        echo "❌ Erro: Nenhum repositório de segurança encontrado em $BASE_DIR"
        exit 1
    fi
    echo -e "Total de módulos encontrados: ${#repos[@]}\n"
    for repo_path in "${repos[@]}"; do
        local repo_name=$(basename "$repo_path")
        local description=$(get_repo_description "$repo_name")
        local status=$(validate_repo_integrity "$repo_path")
        
        echo "📌 Repositório: $repo_name"
        echo "   📁 Diretório : $repo_path"
        if [[ "$status" == "INTEGRO" ]]; then
            echo "   ✅ Status    : ÍNTEGRO (Scan, Plan e Remediate presentes)"
        else
            echo "   ⚠️ Status    : $status"
        fi
        echo "   💡 Descrição : $description"
        echo "----------------------------------------------------"
    done
    exit 0
}

run_scan_all() {
    echo "===================================================="
    echo " AWS Security Control Plane: MODO SCAN-ALL "
    echo "===================================================="
    local repos=($(get_all_repos))
    local total_scans=0
    local success_scans=0

    for repo_path in "${repos[@]}"; do
        local repo_name=$(basename "$repo_path")
        local scan_script=$(find_stage_script "$repo_path" "00")
        local status=$(validate_repo_integrity "$repo_path")

        total_scans=$((total_scans + 1))
        echo -e "\n[$total_scans/${#repos[@]}] Processando: $repo_name"

        if [[ "$status" != "INTEGRO" ]]; then
            echo "   ⚠️ Pulando $repo_name: Repositório não está íntegro ($status)"
            continue
        fi

        echo "   -> Executando SCAN usando: $(basename "$scan_script")..."
        
        # Define PYTHONPATH no diretorio do repo para resolver 'from lib import ...'
        PYTHONPATH="$repo_path" python3 "$scan_script" --region "$AWS_REGION" --output-dir "$BASE_DIR/outputs"
        
        if [ $? -eq 0 ]; then
            local latest_yaml=$(ls -1td "$BASE_DIR/outputs"/202*/*.yaml "$repo_path"/outputs/202*/*.yaml ./202*/*.yaml 2>/dev/null | head -n 1)
            if [ -n "$latest_yaml" ]; then
                anonimize_file "$latest_yaml"
                echo "   ✅ Scan concluído e mascarado: $latest_yaml"
                success_scans=$((success_scans + 1))
            fi
        else
            echo "   ❌ Falha na execução do Scan em $repo_name"
        fi
    done
    
    echo -e "\n===================================================="
    echo " Execução do SCAN-ALL finalizada! "
    echo " Sucesso: $success_scans / $total_scans repositórios íntegros "
    echo "===================================================="
    exit 0
}

case "$1" in
    "list-repos") run_list_repos ;;
    "scan-all") run_scan_all ;;
esac

SELECTED_REPO="${1:-$DEFAULT_REPO}"
REMEDIATION_MODE="${2:-dry-run}"

if [[ "$REMEDIATION_MODE" != "dry-run" && "$REMEDIATION_MODE" != "apply" ]]; then
    echo "❌ Erro: Modo de remediação inválido '$REMEDIATION_MODE'."
    echo "Uso:"
    echo "  $0 list-repos"
    echo "  $0 scan-all"
    echo "  $0 [nome_do_repo] [dry-run|apply]"
    exit 1
fi

REPO_DIR="$BASE_DIR/$SELECTED_REPO"
PLAN_OUTPUT="$BASE_DIR/remediation_plan.yaml"
REPO_DESC=$(get_repo_description "$SELECTED_REPO")

echo "===================================================="
echo " AWS Security Control Plane Automation Suite "
echo " Repositório Alvo: $SELECTED_REPO "
echo " Diretório Path  : $REPO_DIR "
echo " Descrição       : $REPO_DESC "
echo " Modo Remediação : $REMEDIATION_MODE "
echo "===================================================="

if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Erro: O repositório '$REPO_DIR' não foi encontrado em $BASE_DIR."
    exit 1
fi

INTEGRITY_STATUS=$(validate_repo_integrity "$REPO_DIR")
if [[ "$INTEGRITY_STATUS" != "INTEGRO" ]]; then
    echo "❌ Erro: O repositório '$SELECTED_REPO' não atende ao critério de integridade!"
    echo "   Detalhes: $INTEGRITY_STATUS"
    exit 1
fi

cd "$REPO_DIR" || exit 1

RULES_FILE=$(find_rules_file "$REPO_DIR")

# 1. FASE 00: SCAN
SCAN_SCRIPT=$(find_stage_script "$REPO_DIR" "00")
echo -e "\n[1/3] Executando SCAN usando: $(basename "$SCAN_SCRIPT")..."
PYTHONPATH="$REPO_DIR" python3 "$SCAN_SCRIPT" --region "$AWS_REGION" --output-dir "$BASE_DIR/outputs"

INPUT_YAML=$(ls -1td "$BASE_DIR/outputs"/202*/*.yaml "$REPO_DIR"/outputs/202*/*.yaml ./202*/*.yaml 2>/dev/null | head -n 1)

if [ -z "$INPUT_YAML" ]; then
    echo "❌ Erro: Nenhum arquivo YAML de scan foi gerado."
    exit 1
fi

anonimize_file "$INPUT_YAML"
echo "-> Artefato de entrada preparado e mascarado: $INPUT_YAML"

# 2. FASE 01: PLAN
PLAN_SCRIPT=$(find_stage_script "$REPO_DIR" "01")
echo -e "\n[2/3] Executando PLAN usando: $(basename "$PLAN_SCRIPT")..."
if [ -n "$RULES_FILE" ]; then
    PYTHONPATH="$REPO_DIR" python3 "$PLAN_SCRIPT" --input-yaml "$INPUT_YAML" --rules "$RULES_FILE" --output-yaml "$PLAN_OUTPUT"
else
    PYTHONPATH="$REPO_DIR" python3 "$PLAN_SCRIPT" --input-yaml "$INPUT_YAML" --output-yaml "$PLAN_OUTPUT"
fi

if [ ! -f "$PLAN_OUTPUT" ]; then
    echo "❌ Erro: Falha ao gerar o plano de ação $PLAN_OUTPUT"
    exit 1
fi

anonimize_file "$PLAN_OUTPUT"

# 3. FASE 02: REMEDIATE
REMEDIATE_SCRIPT=$(find_stage_script "$REPO_DIR" "02")
echo -e "\n[3/3] Executando REMEDIATE em modo [$REMEDIATION_MODE] usando: $(basename "$REMEDIATE_SCRIPT")..."
PYTHONPATH="$REPO_DIR" python3 "$REMEDIATE_SCRIPT" --region "$AWS_REGION" --yaml "$PLAN_OUTPUT" --mode "$REMEDIATION_MODE"

echo -e "\n===================================================="
echo " Execução finalizada com sucesso! "
echo " Repositório: $SELECTED_REPO "
echo " Plano salvo em: $PLAN_OUTPUT "
echo "===================================================="
