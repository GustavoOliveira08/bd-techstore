# 🛒 Banco de Dados `loja_tech`

Este repositório contém a estrutura, dados iniciais e rotinas (*Stored Procedures*) do banco de dados **Loja Tech**, um sistema relacional desenvolvido em **MySQL 8.0** para gerenciar as operações de um e-commerce de produtos de tecnologia.

## 🏗️ Arquitetura e Tabelas

O banco de dados foi modelado para garantir a integridade referencial, rastreabilidade de operações e consistência no controle de estoque e vendas. Abaixo está o detalhamento de cada tabela e sua necessidade no sistema:

### 1. `categorias`
* **O que faz:** Armazena as classificações dos produtos vendidos na loja (ex: *Notebooks, Smartphones, Periféricos*).
* **Por que é necessária:** Evita a redundância de dados textual na tabela de produtos e permite agrupar, filtrar e gerar relatórios gerenciais por segmento de mercado. Possui controle de ativação (`ativo`) para permitir ocultar categorias sem apagar o histórico.

### 2. `produtos`
* **O que faz:** Contém o catálogo completo de itens, incluindo preço, descrição, quantidade atual em estoque e estoque mínimo aceitável.
* **Por que é necessária:** É o coração do e-commerce. O vínculo com `categorias` organiza o catálogo, enquanto os campos `estoque` e `estoque_minimo` permitem o controle automatizado de disponibilidade e alertas de reposição.

### 3. `clientes`
* **O que faz:** Guarda os dados cadastrais dos compradores (nome, e-mail, CPF, telefone e data de nascimento).
* **Por que é necessária:** Centraliza as informações dos usuários para faturamento, entrega e análise de perfil. As restrições `UNIQUE` em `email` e `cpf` impedem cadastros duplicados e garantem a unicidade de cada consumidor.

### 4. `pedidos`
* **O que faz:** Registra o cabeçalho de cada compra realizada, vinculando o cliente, a data, o valor total e o status atual do fluxo de entrega (`pendente`, `processando`, `enviado`, `entregue`, `cancelado`).
* **Por que é necessária:** Gerencia o ciclo de vida da venda. Permite acompanhar em que etapa logística a compra se encontra e serve como entidade principal para o faturamento.

### 5. `itens_pedido`
* **O que faz:** Detalha quais produtos, em quais quantidades e por qual preço unitário foram comprados em cada pedido. Possui uma coluna calculada (`subtotal`) gerada automaticamente (`quantidade * preco_unitario`).
* **Por que é necessária:** Resolve o relacionamento *Muitos-para-Muitos* entre `pedidos` e `produtos`. Além disso, gravar o `preco_unitario` no momento da compra garante que alterações futuras no preço do produto não distorçam o histórico financeiro de pedidos antigos.

### 6. `log_operacoes`
* **O que faz:** Registra um histórico de auditoria (quem fez, quando fez, em qual tabela e o que foi alterado).
* **Por que é necessária:** Garante **segurança e rastreabilidade (auditoria)**. Em operações críticas como cadastro de produtos, fechamento de pedidos ou cancelamentos, o sistema guarda um rastro permanente para investigação de falhas ou fraudes.

### 7. `cupons_desconto`
* **O que faz:** Armazena códigos promocionais únicos, seus respectivos percentuais de desconto e se já foram utilizados.
* **Por que é necessária:** Viabiliza campanhas de marketing e retenção de clientes diretamente na camada de dados.

---

## ⚙️ Stored Procedures (Rotinas e Evidências de Execução)

As *Stored Procedures* encapsulam as regras de negócio dentro do banco de dados, garantindo performance, segurança e consistência transacional. Abaixo estão as rotinas acompanhadas de seus códigos e resultados reais no MySQL Workbench.

### 📦 Gestão de Produtos e Estoque

#### 1. `listar_produtos_ativos`
* **O que faz:** Retorna todos os produtos ativos cruzados com o nome de suas categorias e classifica a situação do estoque em `'BAIXO'`, `'ATENCAO'` ou `'OK'` com base no estoque mínimo.
* **Por que é necessária:** Facilita a visualização rápida para a equipe de compras e logística identificarem quais produtos precisam de reposição imediata sem precisar fazer cálculos manuais.

```sql
CALL listar_produtos_ativos();
```
![Execução listar_produtos_ativos](./img/Captura%20de%20tela%202026-11-25%20150114.png)

#### 2. `resumo_estoque`
* **O que faz:** Calcula o total de produtos ativos, o valor financeiro total imobilizado em estoque (`preco * estoque`) e a quantidade de itens com estoque crítico.
* **Por que é necessária:** Fornece um *dashboard* executivo instantâneo sobre a saúde financeira e física do inventário da empresa.

```sql
CALL resumo_estoque();
```
![Execução resumo_estoque](./img/Captura%20de%20tela%202026-11-25%20150204.png)

#### 3. `buscar_produtos_por_categoria`
* **O que faz:** Filtra e ordena alfabeticamente os produtos ativos de uma categoria específica informada por parâmetro (`p_id_categoria`).
* **Por que é necessária:** Otimiza a consulta mais comum de um e-commerce (navegação por departamentos), entregando apenas os dados essenciais para a vitrine da loja.

**Exemplo 1: Buscando categoria `1` (Notebooks)**
```sql
CALL buscar_produtos_por_categoria(1);
```
![Execução buscar_produtos_por_categoria 1](./img/Captura%20de%20tela%202026-11-25%20150220.png)

**Exemplo 2: Buscando categoria `3` (Periféricos)**
```sql
CALL buscar_produtos_por_categoria(3);
```
![Execução buscar_produtos_por_categoria 3](./img/Captura%20de%20tela%202026-11-25%20150231.png)

#### 4. `cadastrar_produto`
* **O que faz:** Valida os dados de entrada (nome não vazio, preço maior que zero, categoria ativa e inexistência de produto duplicado na mesma categoria) antes de inserir um novo item e registrar a ação no log.
* **Por que é necessária:** Impede a inserção de dados corrompidos ou inconsistentes (como preços negativos ou categorias inexistentes) diretamente na fonte, protegendo a integridade do catálogo.

```sql
CALL cadastrar_produto(3, 'Webcam Logitech C920', 'Full HD 1080p', 399.90, 20, 5, @id, @msg);
SELECT @id AS id_gerado, @msg AS mensagem;
```

---

### 🛒 Fluxo de Pedidos e Vendas

#### 5. `calcular_frete`
* **O que faz:** Calcula o valor do frete com base no valor total da compra (Grátis acima de R$ 500, R$ 25 entre R$ 200 e R$ 499,99, e R$ 45 abaixo de R$ 200) e retorna uma mensagem incentivando o cliente a atingir o valor para frete grátis.
* **Por que é necessária:** Centraliza a regra de negócio logística e atua como ferramenta de conversão de vendas (*upsell*), incentivando o aumento do ticket médio.

```sql
CALL calcular_frete(350.00, @frete, @msg);
SELECT @frete, @msg;
```
![Execução calcular_frete](./img/Captura%20de%20tela%202026-11-25%20150328.png)

#### 6. `registrar_pedido`
* **O que faz:** Executa uma transação completa (`START TRANSACTION` / `COMMIT`): cria o pedido, verifica se há estoque suficiente para até 3 produtos, insere os itens, dá baixa no estoque, calcula o valor total do pedido e grava o log. Se qualquer etapa falhar (ex: falta de estoque), desfaz tudo (`ROLLBACK`).
* **Por que é necessária:** É a rotina mais crítica do sistema. Garante a **atomicidade** da venda — impede que um produto seja vendido sem estoque ou que o estoque seja reduzido sem que o pedido seja devidamente registrado.

```sql
CALL registrar_pedido(1, 'Presente de aniversario', 1, 1, 5, 2, 6, 1, @pedido, @total, @msg);
SELECT @pedido, @total, @msg;
```

#### 7. `cancelar_pedido`
* **O que faz:** Verifica se o pedido ainda está `'pendente'` ou `'processando'`. Caso positivo, altera o status para `'cancelado'`, devolve os itens ao estoque, anexa o motivo na observação e registra a operação no log.
* **Por que é necessária:** Evita prejuízos operacionais (impedindo o cancelamento de produtos já enviados/entregues) e garante que o estoque retorne automaticamente para a prateleira virtual sem intervenção manual.

```sql
CALL cancelar_pedido(3, 'Cliente desistiu da compra', @msg);
SELECT @msg;
```

#### 8. `descrever_status_pedido`
* **O que faz:** Traduz o código técnico do status do pedido (ex: `'processando'`) em uma mensagem amigável para o cliente final (ex: *"Pagamento confirmado, preparando envio"*).
* **Por que é necessária:** Padroniza a comunicação com o usuário final, centralizando as mensagens de rastreio no banco para que qualquer interface (site, app, WhatsApp) exiba a mesma informação.

```sql
CALL descrever_status_pedido(1, @desc);
SELECT @desc;
```

---

### 👥 Gestão de Clientes e Marketing

#### 9. `contar_pedidos_cliente`
* **O que faz:** Conta quantos pedidos válidos (não cancelados) um cliente possui e o classifica em níveis de fidelidade: `'Novo'`, `'Regular'`, `'Frequente'` ou `'VIP'`.
* **Por que é necessária:** Permite segmentar a base de clientes para ações de CRM, programas de fidelidade e atendimento prioritário.

```sql
CALL contar_pedidos_cliente(1, @total, @classe);
SELECT @total AS total_pedidos, @classe AS classificacao;
```
![Execução contar_pedidos_cliente](./img/Captura%20de%20tela%202026-11-25%20150254.png)

#### 10. `aplicar_desconto`
* **O que faz:** Recebe um valor monetário e um percentual, alterando diretamente a variável de entrada (`INOUT`) com o desconto aplicado.
* **Por que é necessária:** Utilitário reutilizável para cálculos promocionais rápidos durante o checkout ou campanhas sazonais.

```sql
SET @meu_preco = 1000.00;
CALL aplicar_desconto(@meu_preco, 15);
SELECT @meu_preco AS preco_com_desconto;
```
![Execução aplicar_desconto](./img/Captura%20de%20tela%202026-11-25%20150312.png)

#### 11. `validar_idade_cliente`
* **O que faz:** Calcula a idade a partir da data de nascimento e dispara erros personalizados (`SIGNAL SQLSTATE`) caso o cliente seja menor de 18 anos ou tenha uma data irreal (> 120 anos).
* **Por que é necessária:** Garante conformidade legal (impedindo vendas para menores de idade) e previne erros de digitação no cadastro.

```sql
CALL validar_idade_cliente('2000-01-30');
```

#### 12. `gerar_cupons`
* **O que faz:** Gera em lote uma quantidade específica de códigos alfanuméricos aleatórios de 8 caracteres (via hash `MD5`) com um percentual de desconto definido.
* **Por que é necessária:** Automatiza a criação de campanhas promocionais em escala, garantindo códigos únicos e imprevisíveis sem trabalho manual.

```sql
CALL gerar_cupons(10, 20.00);
```

---

### 📊 Inteligência de Negócios e Utilitários

#### 13. `relatorio_vendas_periodo`
* **O que faz:** Recebe uma data inicial e final e retorna três conjuntos de resultados: resumo financeiro (receita, ticket médio, etc.), ranking dos **Top 10 produtos** mais vendidos e ranking dos **Top 5 clientes** que mais gastaram.
* **Por que é necessária:** Entrega inteligência de negócios (BI) pronta para tomada de decisão gerencial, eliminando a necessidade de exportar dados para planilhas externas.

```sql
CALL relatorio_vendas_periodo('2026-11-01', '2026-11-30');
```

#### 14. `ola_mundo`, Verificação de Status & `demonstrar_handlers`
* **O que faz:** Rotinas auxiliares de teste de conectividade (`ola_mundo`), listagem de metadados (`SHOW PROCEDURE STATUS`) e exemplificação de tratamento de exceções SQL (`demonstrar_handlers`).
* **Por que é necessária:** Servem como base estrutural e validação de ambiente para desenvolvedores que mantêm o banco de dados.

**Criação da tabela de log e execução inicial (`ola_mundo`):**
```sql
CALL ola_mundo();
```
![Ambiente completo e execução ola_mundo](./img/Captura%20de%20tela%202026-11-25%20145921.png)

**Detalhe da execução da procedure `ola_mundo`:**
```sql
DELIMITER //
CREATE PROCEDURE ola_mundo()
BEGIN
    SELECT 'Ola, mundo! Esta e minha primeira Stored Procedure!' AS mensagem;
END //
DELIMITER ;
CALL ola_mundo();
```
![Detalhe execução ola_mundo](./img/Captura%20de%20tela%202026-11-25%20145942.png)

**Listagem de status das procedures criadas no banco `loja_tech`:**
```sql
SHOW PROCEDURE STATUS WHERE Db = 'loja_tech';
```
![Status das procedures](./img/Captura%20de%20tela%202026-11-25%20150141.png)

---

## 🚀 Como Executar

1. Execute o script de criação das tabelas e rotinas (`database_tables_functions.sql`).
2. Popule o banco com os dados iniciais utilizando o script de inserção (`database_inserts.sql`).
3. Todos os prints de execução estão armazenados no diretório `./img/` e vinculados às suas respectivas chamadas acima.