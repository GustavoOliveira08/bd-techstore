-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: loja_tech
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping events for database 'loja_tech'
--

--
-- Dumping routines for database 'loja_tech'
--
/*!50003 DROP PROCEDURE IF EXISTS `aplicar_desconto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `aplicar_desconto`(
    INOUT p_preco DECIMAL(10,2),
    IN p_percentual DECIMAL(5,2)
)
BEGIN
    SET p_preco = p_preco - (p_preco * p_percentual / 100);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `buscar_produtos_por_categoria` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `buscar_produtos_por_categoria`(IN p_id_categoria INT)
BEGIN
    SELECT p.id_produto, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.id_categoria = p_id_categoria AND p.ativo = TRUE
    ORDER BY p.nome;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `cadastrar_produto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `cadastrar_produto`(
    IN p_id_categoria INT,
    IN p_nome VARCHAR(200),
    IN p_descricao TEXT,
    IN p_preco DECIMAL(10,2),
    IN p_estoque INT,
    IN p_estoque_minimo INT,
    OUT p_id_gerado INT,
    OUT p_mensagem VARCHAR(255)
)
BEGIN
    DECLARE v_categoria_existe INT DEFAULT 0;
    DECLARE v_produto_existe INT DEFAULT 0;

    IF p_nome IS NULL OR TRIM(p_nome) = '' THEN
        SET p_id_gerado = 0;
        SET p_mensagem = 'ERRO: O nome do produto e obrigatorio.';
    ELSEIF p_preco <= 0 THEN
        SET p_id_gerado = 0;
        SET p_mensagem = 'ERRO: O preco deve ser maior que zero.';
    ELSE
        SELECT COUNT(*) INTO v_categoria_existe
        FROM categorias
        WHERE id_categoria = p_id_categoria AND ativo = TRUE;

        IF v_categoria_existe = 0 THEN
            SET p_id_gerado = 0;
            SET p_mensagem = 'ERRO: Categoria nao encontrada ou inativa.';
        ELSE
            SELECT COUNT(*) INTO v_produto_existe
            FROM produtos
            WHERE nome = p_nome AND id_categoria = p_id_categoria;

            IF v_produto_existe > 0 THEN
                SET p_id_gerado = 0;
                SET p_mensagem = 'ERRO: Ja existe um produto com este nome nesta categoria.';
            ELSE
                INSERT INTO produtos (id_categoria, nome, descricao, preco, estoque, estoque_minimo)
                VALUES (p_id_categoria, TRIM(p_nome), p_descricao, p_preco,
                    IFNULL(p_estoque, 0), IFNULL(p_estoque_minimo, 5));

                SET p_id_gerado = LAST_INSERT_ID();
                SET p_mensagem = CONCAT('Produto cadastrado com sucesso! ID: ', p_id_gerado);

                INSERT INTO log_operacoes (tabela_afetada, operacao, descricao)
                VALUES ('produtos', 'INSERT',
                    CONCAT('Produto criado: ', p_nome, ' | Preco: R$ ', FORMAT(p_preco, 2)));
            END IF;
        END IF;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `calcular_frete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `calcular_frete`(
    IN p_valor_pedido DECIMAL(10,2),
    OUT p_valor_frete DECIMAL(10,2),
    OUT p_mensagem VARCHAR(100)
)
BEGIN
    IF p_valor_pedido >= 500.00 THEN
        SET p_valor_frete = 0.00;
        SET p_mensagem = 'Parabens! Frete gratis!';
    ELSEIF p_valor_pedido >= 200.00 THEN
        SET p_valor_frete = 25.00;
        SET p_mensagem = CONCAT('Frete: R$ 25,00. Faltam R$ ',
            FORMAT(500.00 - p_valor_pedido, 2), ' para frete gratis!');
    ELSE
        SET p_valor_frete = 45.00;
        SET p_mensagem = CONCAT('Frete: R$ 45,00. Faltam R$ ',
            FORMAT(500.00 - p_valor_pedido, 2), ' para frete gratis!');
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `cancelar_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelar_pedido`(
    IN p_id_pedido INT,
    IN p_motivo TEXT,
    OUT p_mensagem VARCHAR(500)
)
BEGIN
    DECLARE v_status_atual VARCHAR(20);
    DECLARE v_cliente VARCHAR(150);
    DECLARE v_total DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensagem = 'ERRO: Falha ao cancelar pedido.';
    END;

    SELECT pe.status, c.nome, pe.valor_total
    INTO v_status_atual, v_cliente, v_total
    FROM pedidos pe
    INNER JOIN clientes c ON c.id_cliente = pe.id_cliente
    WHERE pe.id_pedido = p_id_pedido;

    IF v_status_atual IS NULL THEN
        SET p_mensagem = 'ERRO: Pedido nao encontrado.';
    ELSEIF v_status_atual NOT IN ('pendente', 'processando') THEN
        SET p_mensagem = CONCAT('ERRO: Nao e possivel cancelar pedido com status "', v_status_atual,
            '". So pedidos pendentes ou em processamento.');
    ELSE
        START TRANSACTION;
        UPDATE produtos pr
        INNER JOIN itens_pedido ip ON ip.id_produto = pr.id_produto
        SET pr.estoque = pr.estoque + ip.quantidade
        WHERE ip.id_pedido = p_id_pedido;

        UPDATE pedidos
        SET status = 'cancelado',
            observacao = CONCAT(IFNULL(observacao, ''), '\\n[CANCELADO] ', NOW(),
                ' - ', IFNULL(p_motivo, 'Sem motivo'))
        WHERE id_pedido = p_id_pedido;

        INSERT INTO log_operacoes (tabela_afetada, operacao, descricao)
        VALUES ('pedidos', 'CANCELAMENTO',
            CONCAT('Pedido #', p_id_pedido, ' | Cliente: ', v_cliente,
            ' | Valor: R$ ', FORMAT(v_total, 2), ' | Motivo: ',
            IFNULL(p_motivo, 'Nao informado')));
        COMMIT;
        SET p_mensagem = CONCAT('Pedido #', p_id_pedido,
            ' cancelado com sucesso. Estoque restaurado.');
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `contar_pedidos_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `contar_pedidos_cliente`(
    IN p_id_cliente INT,
    OUT p_total_pedidos INT,
    OUT p_classificacao VARCHAR(20)
)
BEGIN
    SELECT COUNT(*) INTO p_total_pedidos
    FROM pedidos
    WHERE id_cliente = p_id_cliente AND status <> 'cancelado';

    IF p_total_pedidos >= 10 THEN
        SET p_classificacao = 'VIP';
    ELSEIF p_total_pedidos >= 5 THEN
        SET p_classificacao = 'Frequente';
    ELSEIF p_total_pedidos >= 1 THEN
        SET p_classificacao = 'Regular';
    ELSE
        SET p_classificacao = 'Novo';
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `descrever_status_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `descrever_status_pedido`(
    IN p_id_pedido INT,
    OUT p_descricao VARCHAR(200)
)
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM pedidos WHERE id_pedido = p_id_pedido;

    CASE v_status
        WHEN 'pendente' THEN SET p_descricao = 'Pedido recebido, aguardando pagamento.';
        WHEN 'processando' THEN SET p_descricao = 'Pagamento confirmado, preparando envio.';
        WHEN 'enviado' THEN SET p_descricao = 'Pedido a caminho! Acompanhe pelo rastreio.';
        WHEN 'entregue' THEN SET p_descricao = 'Pedido entregue com sucesso!';
        WHEN 'cancelado' THEN SET p_descricao = 'Pedido foi cancelado.';
        ELSE SET p_descricao = 'Status desconhecido.';
    END CASE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `gerar_cupons` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `gerar_cupons`(
    IN p_quantidade INT,
    IN p_percentual DECIMAL(5,2)
)
BEGIN
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_codigo VARCHAR(10);

    WHILE v_contador < p_quantidade DO
        SET v_codigo = UPPER(SUBSTRING(MD5(RAND()), 1, 8));
        INSERT IGNORE INTO cupons_desconto (codigo, percentual)
        VALUES (v_codigo, p_percentual);
        SET v_contador = v_contador + 1;
    END WHILE;

    SELECT CONCAT(v_contador, ' cupons de ', p_percentual,
        '% gerados com sucesso!') AS resultado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `listar_produtos_ativos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `listar_produtos_ativos`()
BEGIN
    SELECT p.id_produto, p.nome AS produto, c.nome AS categoria, p.preco, p.estoque,
        CASE
            WHEN p.estoque <= p.estoque_minimo THEN 'BAIXO'
            WHEN p.estoque <= p.estoque_minimo * 2 THEN 'ATENCAO'
            ELSE 'OK'
        END AS situacao_estoque
    FROM produtos p
    INNER JOIN categorias c ON c.id_categoria = p.id_categoria
    WHERE p.ativo = TRUE
    ORDER BY c.nome, p.nome;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `ola_mundo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `ola_mundo`()
BEGIN
    SELECT 'Ola, mundo! Esta e minha primeira Stored Procedure!' AS mensagem;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `registrar_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_pedido`(
    IN p_id_cliente INT,
    IN p_observacao TEXT,
    IN p_produto_1 INT, IN p_qtd_1 INT,
    IN p_produto_2 INT, IN p_qtd_2 INT,
    IN p_produto_3 INT, IN p_qtd_3 INT,
    OUT p_id_pedido INT,
    OUT p_valor_total DECIMAL(10,2),
    OUT p_mensagem VARCHAR(500)
)
BEGIN
    DECLARE v_preco DECIMAL(10,2);
    DECLARE v_estoque INT;
    DECLARE v_nome_prod VARCHAR(200);
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_id_pedido = 0;
        SET p_valor_total = 0;
        SET p_mensagem = 'ERRO: Falha ao registrar pedido. Operacao cancelada.';
    END;

    START TRANSACTION;

    INSERT INTO pedidos (id_cliente, observacao)
    VALUES (p_id_cliente, p_observacao);
    SET p_id_pedido = LAST_INSERT_ID();

    IF p_produto_1 IS NOT NULL AND p_produto_1 > 0 THEN
        SELECT preco, estoque, nome INTO v_preco, v_estoque, v_nome_prod
        FROM produtos WHERE id_produto = p_produto_1;
        IF v_estoque < p_qtd_1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para o produto 1';
        END IF;
        INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
        VALUES (p_id_pedido, p_produto_1, p_qtd_1, v_preco);
        UPDATE produtos SET estoque = estoque - p_qtd_1 WHERE id_produto = p_produto_1;
        SET v_total = v_total + (v_preco * p_qtd_1);
    END IF;


    IF p_produto_2 IS NOT NULL AND p_produto_2 > 0 THEN
        SELECT preco, estoque, nome INTO v_preco, v_estoque, v_nome_prod
        FROM produtos WHERE id_produto = p_produto_2;
        IF v_estoque < p_qtd_2 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para o produto 2';
        END IF;
        INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
        VALUES (p_id_pedido, p_produto_2, p_qtd_2, v_preco);
        UPDATE produtos SET estoque = estoque - p_qtd_2 WHERE id_produto = p_produto_2;
        SET v_total = v_total + (v_preco * p_qtd_2);
    END IF;


    IF p_produto_3 IS NOT NULL AND p_produto_3 > 0 THEN
        SELECT preco, estoque, nome INTO v_preco, v_estoque, v_nome_prod
        FROM produtos WHERE id_produto = p_produto_3;
        IF v_estoque < p_qtd_3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para o produto 3';
        END IF;
        INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
        VALUES (p_id_pedido, p_produto_3, p_qtd_3, v_preco);
        UPDATE produtos SET estoque = estoque - p_qtd_3 WHERE id_produto = p_produto_3;
        SET v_total = v_total + (v_preco * p_qtd_3);
    END IF;

    UPDATE pedidos SET valor_total = v_total WHERE id_pedido = p_id_pedido;

    INSERT INTO log_operacoes (tabela_afetada, operacao, descricao)
    VALUES ('pedidos', 'INSERT',
        CONCAT('Pedido #', p_id_pedido, ' | Cliente: ', p_id_cliente,
        ' | Valor: R$ ', FORMAT(v_total, 2)));

    COMMIT;
    SET p_valor_total = v_total;
    SET p_mensagem = CONCAT('Pedido #', p_id_pedido, ' registrado com sucesso! Total: R$ ',
        FORMAT(v_total, 2));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `relatorio_vendas_periodo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `relatorio_vendas_periodo`(
    IN p_data_inicio DATE,
    IN p_data_fim DATE
)
BEGIN

    SELECT COUNT(DISTINCT p.id_pedido) AS total_pedidos,
        COUNT(DISTINCT p.id_cliente) AS clientes_distintos,
        SUM(p.valor_total) AS receita_total,
        AVG(p.valor_total) AS ticket_medio,
        MAX(p.valor_total) AS maior_pedido,
        MIN(p.valor_total) AS menor_pedido
    FROM pedidos p
    WHERE p.data_pedido BETWEEN p_data_inicio AND CONCAT(p_data_fim, ' 23:59:59')
      AND p.status <> 'cancelado';

    SELECT pr.nome AS produto, SUM(ip.quantidade) AS qtd_vendida,
        SUM(ip.subtotal) AS total_vendido
    FROM itens_pedido ip
    INNER JOIN pedidos pe ON pe.id_pedido = ip.id_pedido
    INNER JOIN produtos pr ON pr.id_produto = ip.id_produto
    WHERE pe.data_pedido BETWEEN p_data_inicio AND CONCAT(p_data_fim, ' 23:59:59')
      AND pe.status <> 'cancelado'
    GROUP BY pr.id_produto, pr.nome
    ORDER BY qtd_vendida DESC
    LIMIT 10;

    SELECT c.nome AS cliente, COUNT(pe.id_pedido) AS qtd_pedidos,
        SUM(pe.valor_total) AS total_gasto
    FROM clientes c
    INNER JOIN pedidos pe ON pe.id_cliente = c.id_cliente
    WHERE pe.data_pedido BETWEEN p_data_inicio AND CONCAT(p_data_fim, ' 23:59:59')
      AND pe.status <> 'cancelado'
    GROUP BY c.id_cliente, c.nome
    ORDER BY total_gasto DESC
    LIMIT 5;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `resumo_estoque` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `resumo_estoque`()
BEGIN
    DECLARE v_total_produtos INT DEFAULT 0;
    DECLARE v_valor_estoque DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_produtos_baixo INT DEFAULT 0;

    SELECT COUNT(*), SUM(preco * estoque)
    INTO v_total_produtos, v_valor_estoque
    FROM produtos
    WHERE ativo = TRUE;

    SELECT COUNT(*)
    INTO v_produtos_baixo
    FROM produtos
    WHERE ativo = TRUE AND estoque <= estoque_minimo;

    SELECT v_total_produtos AS total_produtos_ativos,
           v_valor_estoque AS valor_total_em_estoque,
           v_produtos_baixo AS produtos_estoque_baixo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `validar_idade_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `validar_idade_cliente`(IN p_data_nascimento DATE)
BEGIN
    DECLARE v_idade INT;
    SET v_idade = TIMESTAMPDIFF(YEAR, p_data_nascimento, CURDATE());

    IF v_idade < 18 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cliente deve ter pelo menos 18 anos.',
                MYSQL_ERRNO = 5001;
    ELSEIF v_idade > 120 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Data de nascimento invalida.',
                MYSQL_ERRNO = 5002;
    ELSE
        SELECT CONCAT('Idade valida: ', v_idade, ' anos.') AS resultado;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-24 19:42:37
