-- ================================================================
-- Script de geração de dados mock históricos - SQL puro
-- Simula estoque de restaurante com alta rotatividade (PF + Feijoada)
-- ================================================================

USE toomate;

-- ================================================================
-- CONFIGURAÇÕES
-- ================================================================
SET @SEED = 20260531;
SET @START_DATE = '2026-01-01';
SET @END_DATE = CURDATE();

SET @SEED_INITIAL_INVENTORY = TRUE;
SET @INITIAL_INVENTORY_DATE = '2026-01-01 08:00:00';
SET @FORCE_RECREATE_INITIAL_INVENTORY = FALSE;

SET @INITIAL_EXTRA_LOTS_MIN = 0;
SET @INITIAL_EXTRA_LOTS_MAX = 1;

-- Retiradas diárias (consumo do restaurante: 12-28 operações/dia)
SET @RETIRADAS_MIN = 12;
SET @RETIRADAS_MAX = 28;
SET @RETIRADA_QTD_MIN = 1;
SET @RETIRADA_QTD_MAX = 3;

-- Compras semanais
SET @CHANCE_COMPRA_DIARIA = 0.08;

-- Bulk restock a cada 14 dias
SET @BULK_RESTOCK_MAX_GAP = 14;
SET @BULK_RESTOCK_CHANCE = 0.20;

-- Expiração
SET @EXPIRE_GRACE_DAYS = 2;
SET @DELETE_EXPIRED_LOTS = TRUE;

-- Reset opcional
SET @RESET_HISTORICO_LOTE = FALSE;
SET @RESET_LOTE = FALSE;

-- ================================================================
-- HELPER: Tabela temporária para controle de data
-- ================================================================
DROP TEMPORARY TABLE IF EXISTS temp_date_range;
CREATE TEMPORARY TABLE temp_date_range (
    data_dia DATE PRIMARY KEY
);

-- Popula range de datas de @START_DATE até @END_DATE
DELIMITER $$
BEGIN
    DECLARE v_current_date DATE;
    SET v_current_date = @START_DATE;
    
    WHILE v_current_date <= @END_DATE DO
        INSERT IGNORE INTO temp_date_range VALUES (v_current_date);
        SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

-- ================================================================
-- HELPER: Tabela de mapeamento insumo-multiplicador (alta demanda)
-- ================================================================
DROP TEMPORARY TABLE IF EXISTS temp_insumos_alta_demanda;
CREATE TEMPORARY TABLE temp_insumos_alta_demanda (
    nome_insumo VARCHAR(100),
    multiplicador DECIMAL(3,2),
    PRIMARY KEY (nome_insumo)
) AS
SELECT 'Arroz Branco', 1.5 UNION ALL
SELECT 'Feijão Carioca', 1.8 UNION ALL
SELECT 'Macarrão Espaguete', 1.4 UNION ALL
SELECT 'Óleo de Soja', 1.6 UNION ALL
SELECT 'Sal Refinado', 1.3 UNION ALL
SELECT 'Peito de Frango', 1.5 UNION ALL
SELECT 'Carne Bovina Moída', 1.5 UNION ALL
SELECT 'Carne Suína', 1.8 UNION ALL
SELECT 'Linguiça Toscana', 1.6 UNION ALL
SELECT 'Bacon', 1.6 UNION ALL
SELECT 'Molho de Tomate', 1.4 UNION ALL
SELECT 'Cebola', 1.5 UNION ALL
SELECT 'Alho', 1.4;

-- ================================================================
-- HELPER: Função para gerar data de validade por categoria
-- ================================================================
DELIMITER $$
CREATE FUNCTION fn_dias_validade_min(fkCategoria INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    CASE fkCategoria
        WHEN 3 THEN RETURN 2;        -- hortifruti
        WHEN 1 THEN RETURN 3;        -- proteínas
        WHEN 2 THEN RETURN 3;        -- pescados
        WHEN 5 THEN RETURN 3;        -- frios
        WHEN 4 THEN RETURN 7;        -- laticínios
        WHEN 6 THEN RETURN 90;       -- grãos
        WHEN 7 THEN RETURN 90;       -- temperos
        WHEN 8 THEN RETURN 90;       -- óleos
        WHEN 9 THEN RETURN 45;       -- bebidas
        ELSE RETURN 30;
    END CASE;
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION fn_dias_validade_max(fkCategoria INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    CASE fkCategoria
        WHEN 3 THEN RETURN 9;        -- hortifruti
        WHEN 1 THEN RETURN 20;       -- proteínas
        WHEN 2 THEN RETURN 20;       -- pescados
        WHEN 5 THEN RETURN 20;       -- frios
        WHEN 4 THEN RETURN 45;       -- laticínios
        WHEN 6 THEN RETURN 540;      -- grãos
        WHEN 7 THEN RETURN 540;      -- temperos
        WHEN 8 THEN RETURN 540;      -- óleos
        WHEN 9 THEN RETURN 300;      -- bebidas
        ELSE RETURN 180;
    END CASE;
END$$
DELIMITER ;

-- ================================================================
-- HELPER: Função para gerar unidade de medida padrão
-- ================================================================
DELIMITER $$
CREATE FUNCTION fn_unidade_medida(insumo_nome VARCHAR(100))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE n VARCHAR(100);
    SET n = LOWER(insumo_nome);
    
    CASE
        WHEN n LIKE '%arroz%' THEN RETURN 'kg';
        WHEN n LIKE '%feijão%' THEN RETURN 'kg';
        WHEN n LIKE '%macarrão%' THEN RETURN 'kg';
        WHEN n LIKE '%farinha%' THEN RETURN 'kg';
        WHEN n LIKE '%sal%' THEN RETURN 'kg';
        WHEN n LIKE '%frango%' OR n LIKE '%tilápia%' OR n LIKE '%carne%' 
             OR n LIKE '%linguiça%' OR n LIKE '%bacon%' OR n LIKE '%presunto%' 
             OR n LIKE '%sardinha%' THEN RETURN 'kg';
        WHEN n LIKE '%pimenta%' THEN RETURN 'g';
        WHEN n LIKE '%molho%' THEN RETURN 'g';
        WHEN n LIKE '%vinagre%' THEN RETURN 'ml';
        WHEN n LIKE '%óleo%' OR n LIKE '%oleo%' THEN RETURN 'ml';
        WHEN n LIKE '%azeite%' THEN RETURN 'ml';
        WHEN n LIKE '%leite%' THEN RETURN 'L';
        WHEN n LIKE '%queijo%' OR n LIKE '%manteiga%' THEN RETURN 'kg';
        WHEN n LIKE '%cebola%' OR n LIKE '%alho%' OR n LIKE '%tomate%' THEN RETURN 'kg';
        WHEN n LIKE '%refrigerante%' OR n LIKE '%água%' OR n LIKE '%suco%' THEN RETURN 'L';
        ELSE RETURN 'kg';
    END CASE;
END$$
DELIMITER ;

-- ================================================================
-- HELPER: Função para gerar quantidade medida por unidade comercial
-- ================================================================
DELIMITER $$
CREATE FUNCTION fn_quantidade_medida(insumo_nome VARCHAR(100))
RETURNS FLOAT
DETERMINISTIC
BEGIN
    DECLARE n VARCHAR(100);
    SET n = LOWER(insumo_nome);
    
    CASE
        WHEN n LIKE '%arroz%' THEN RETURN 5.0;           -- saco 5kg
        WHEN n LIKE '%feijão%' THEN RETURN 1.0;          -- saco 1kg
        WHEN n LIKE '%macarrão%' THEN RETURN 1.0;        -- caixa 1kg
        WHEN n LIKE '%farinha%' THEN RETURN 1.0;         -- saco 1kg
        WHEN n LIKE '%sal%' THEN RETURN 1.0;             -- pacote 1kg
        WHEN n LIKE '%pimenta%' THEN RETURN 50.0;        -- pote 50g
        WHEN n LIKE '%molho%' THEN RETURN 340.0;         -- lata 340g
        WHEN n LIKE '%vinagre%' THEN RETURN 750.0;       -- garrafa 750ml
        WHEN n LIKE '%óleo%' OR n LIKE '%oleo%' THEN RETURN 900.0;   -- garrafa 900ml
        WHEN n LIKE '%azeite%' THEN RETURN 500.0;        -- garrafa 500ml
        WHEN n LIKE '%leite%' THEN RETURN 1.0;           -- litro
        WHEN n LIKE '%refrigerante%' THEN RETURN 2.0;    -- garrafa 2L
        WHEN n LIKE '%água%' THEN RETURN 1.0;            -- litro
        WHEN n LIKE '%suco%' THEN RETURN 1.0;            -- litro
        ELSE RETURN 1.0;
    END CASE;
END$$
DELIMITER ;

-- ================================================================
-- HELPER: Função para gerar preço por categoria
-- ================================================================
DELIMITER $$
CREATE FUNCTION fn_preco_base(fkCategoria INT)
RETURNS DECIMAL(8,2)
DETERMINISTIC
BEGIN
    CASE fkCategoria
        WHEN 1 THEN RETURN 50;       -- proteínas
        WHEN 2 THEN RETURN 50;       -- pescados
        WHEN 5 THEN RETURN 50;       -- frios
        WHEN 3 THEN RETURN 15;       -- hortifruti
        WHEN 4 THEN RETURN 50;       -- laticínios
        WHEN 6 THEN RETURN 40;       -- grãos
        WHEN 7 THEN RETURN 15;       -- temperos
        WHEN 8 THEN RETURN 25;       -- óleos
        WHEN 9 THEN RETURN 20;       -- bebidas
        ELSE RETURN 30;
    END CASE;
END$$
DELIMITER ;

-- ================================================================
-- HELPER: Tabela temporária com insumos carregados
-- ================================================================
DROP TEMPORARY TABLE IF EXISTS temp_insumos;
CREATE TEMPORARY TABLE temp_insumos AS
SELECT 
    i.idInsumo,
    i.nome,
    i.fkCategoria,
    i.qtdMinima,
    i.rotatividade,
    COALESCE(m.multiplicador, 1.0) AS mult_alta_demanda
FROM insumo i
LEFT JOIN temp_insumos_alta_demanda m ON i.nome = m.nome_insumo;

-- ================================================================
-- RESET OPCIONAL
-- ================================================================
IF @RESET_HISTORICO_LOTE THEN
    SET FOREIGN_KEY_CHECKS = 0;
    DELETE FROM historicoLote;
    IF @RESET_LOTE THEN
        DELETE FROM lote;
    END IF;
    SET FOREIGN_KEY_CHECKS = 1;
END IF;

-- ================================================================
-- 1. INVENTÁRIO INICIAL
-- ================================================================
IF @SEED_INITIAL_INVENTORY THEN
    -- Verifica se já existe inventário inicial
    IF NOT EXISTS (
        SELECT 1 FROM lote 
        WHERE DATE(dataEntrada) = DATE(@INITIAL_INVENTORY_DATE)
    ) OR @FORCE_RECREATE_INITIAL_INVENTORY THEN
        
        -- Limpa se necessário
        IF @FORCE_RECREATE_INITIAL_INVENTORY THEN
            SET FOREIGN_KEY_CHECKS = 0;
            DELETE hl FROM historicoLote hl
            JOIN lote l ON l.idLote = hl.fkLote
            WHERE DATE(l.dataEntrada) = DATE(@INITIAL_INVENTORY_DATE);
            DELETE FROM lote WHERE DATE(dataEntrada) = DATE(@INITIAL_INVENTORY_DATE);
            SET FOREIGN_KEY_CHECKS = 1;
        END IF;
        
        -- Insere 1 lote por marca (estoque inicial ~75% da qtdMinima semanal)
        INSERT INTO lote 
        (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida,
         quantidadeOriginal, quantidadeAtual, dataEntrada, ativo)
        SELECT 
            m.idMarca,
            (SELECT idUsuario FROM Usuario ORDER BY RAND() LIMIT 1),
            DATE_ADD(
                DATE(@INITIAL_INVENTORY_DATE),
                INTERVAL FLOOR(RAND() * 
                    (fn_dias_validade_max(i.fkCategoria) - fn_dias_validade_min(i.fkCategoria)) 
                    + fn_dias_validade_min(i.fkCategoria)
                ) DAY
            ),
            ROUND(fn_preco_base(i.fkCategoria) * (0.8 + RAND() * 0.4), 2),
            fn_unidade_medida(i.nome),
            fn_quantidade_medida(i.nome),
            GREATEST(1, FLOOR(i.qtdMinima * 0.75)),
            GREATEST(1, FLOOR(i.qtdMinima * 0.75)),
            TIMESTAMP(
                DATE(@INITIAL_INVENTORY_DATE),
                MAKETIME(
                    FLOOR(RAND() * 4) + 8,
                    FLOOR(RAND() * 60),
                    FLOOR(RAND() * 60)
                )
            ),
            1
        FROM marca m
        JOIN temp_insumos i ON m.fkInsumo = i.idInsumo;
        
        -- Insere alguns lotes extras (0-1 por insumo)
        INSERT INTO lote 
        (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida,
         quantidadeOriginal, quantidadeAtual, dataEntrada, ativo)
        SELECT 
            m.idMarca,
            (SELECT idUsuario FROM Usuario ORDER BY RAND() LIMIT 1),
            DATE_ADD(
                DATE(@INITIAL_INVENTORY_DATE),
                INTERVAL FLOOR(RAND() * 
                    (fn_dias_validade_max(i.fkCategoria) - fn_dias_validade_min(i.fkCategoria))
                    + fn_dias_validade_min(i.fkCategoria)
                ) DAY
            ),
            ROUND(fn_preco_base(i.fkCategoria) * (0.8 + RAND() * 0.4), 2),
            fn_unidade_medida(i.nome),
            fn_quantidade_medida(i.nome),
            GREATEST(1, FLOOR(i.qtdMinima * (0.3 + RAND() * 0.3))),
            GREATEST(1, FLOOR(i.qtdMinima * (0.3 + RAND() * 0.3))),
            TIMESTAMP(
                DATE_ADD(DATE(@INITIAL_INVENTORY_DATE), INTERVAL FLOOR(RAND() * 7) DAY),
                MAKETIME(
                    FLOOR(RAND() * 4) + 8,
                    FLOOR(RAND() * 60),
                    FLOOR(RAND() * 60)
                )
            ),
            1
        FROM marca m
        JOIN temp_insumos i ON m.fkInsumo = i.idInsumo
        WHERE RAND() < 0.5;
        
    END IF;
END IF;

-- ================================================================
-- 2. RETIRADAS DIÁRIAS (CONSUMO)
-- ================================================================
-- Popula histórico de retiradas (12-28 operações por dia)
INSERT INTO historicoLote (fkLote, quantidadeRetirada, dataHoraAlteracao)
SELECT 
    l.idLote,
    FLOOR(RAND() * (@RETIRADA_QTD_MAX - @RETIRADA_QTD_MIN + 1)) + @RETIRADA_QTD_MIN,
    TIMESTAMP(
        tdr.data_dia,
        MAKETIME(
            FLOOR(RAND() * 10) + 9,  -- 9:00 - 18:59
            FLOOR(RAND() * 60),
            FLOOR(RAND() * 60)
        )
    )
FROM temp_date_range tdr
CROSS JOIN (
    SELECT idLote FROM lote WHERE ativo = 1 AND quantidadeAtual > 0 ORDER BY RAND() LIMIT 1
) l_sub
JOIN lote l ON l.idLote = l_sub.idLote
WHERE l.dataValidade >= tdr.data_dia
    AND RAND() < ((@RETIRADAS_MAX - @RETIRADAS_MIN + 1) / 86400.0);  -- distribuir ao longo do dia

-- Atualiza quantidadeAtual dos lotes baseado no histórico
UPDATE lote l
SET l.quantidadeAtual = GREATEST(0, l.quantidadeOriginal - (
    SELECT COALESCE(SUM(quantidadeRetirada), 0)
    FROM historicoLote hl
    WHERE hl.fkLote = l.idLote
));

-- ================================================================
-- 3. COMPRAS (REPOSIÇÃO SEMANAL)
-- ================================================================
-- Tabela temporária para rastrear última compra por insumo
DROP TEMPORARY TABLE IF EXISTS temp_last_buy;
CREATE TEMPORARY TABLE temp_last_buy (
    idInsumo INT,
    last_buy_date DATE,
    PRIMARY KEY (idInsumo)
);

-- Insere compras de reposição (1x por semana em média)
INSERT INTO lote 
(fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida,
 quantidadeOriginal, quantidadeAtual, dataEntrada, ativo)
SELECT 
    m.idMarca,
    (SELECT idUsuario FROM Usuario ORDER BY RAND() LIMIT 1),
    DATE_ADD(
        tdr.data_dia,
        INTERVAL FLOOR(RAND() * 
            (fn_dias_validade_max(i.fkCategoria) - fn_dias_validade_min(i.fkCategoria))
            + fn_dias_validade_min(i.fkCategoria)
        ) DAY
    ),
    ROUND(fn_preco_base(i.fkCategoria) * (0.8 + RAND() * 0.4), 2),
    fn_unidade_medida(i.nome),
    fn_quantidade_medida(i.nome),
    GREATEST(1, FLOOR(i.qtdMinima * 1.2 * i.mult_alta_demanda)),
    GREATEST(1, FLOOR(i.qtdMinima * 1.2 * i.mult_alta_demanda)),
    TIMESTAMP(
        tdr.data_dia,
        MAKETIME(
            FLOOR(RAND() * 4) + 7,  -- 7:00 - 10:59 (chegada de manhã)
            FLOOR(RAND() * 60),
            FLOOR(RAND() * 60)
        )
    ),
    1
FROM temp_date_range tdr
CROSS JOIN temp_insumos i
CROSS JOIN (
    SELECT idMarca, fkInsumo FROM marca ORDER BY RAND() LIMIT 1
) m_sub
JOIN marca m ON m.idMarca = m_sub.idMarca AND m.fkInsumo = i.idInsumo
WHERE RAND() < @CHANCE_COMPRA_DIARIA;  -- ~1x a cada ~12 dias por insumo

-- ================================================================
-- 4. BULK RESTOCK (GRANDE REABASTECIMENTO A CADA 14 DIAS)
-- ================================================================
INSERT INTO lote 
(fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida,
 quantidadeOriginal, quantidadeAtual, dataEntrada, ativo)
SELECT 
    m.idMarca,
    (SELECT idUsuario FROM Usuario ORDER BY RAND() LIMIT 1),
    DATE_ADD(
        tdr.data_dia,
        INTERVAL FLOOR(RAND() * 
            (fn_dias_validade_max(i.fkCategoria) - fn_dias_validade_min(i.fkCategoria))
            + fn_dias_validade_min(i.fkCategoria)
        ) DAY
    ),
    ROUND(fn_preco_base(i.fkCategoria) * (0.8 + RAND() * 0.4), 2),
    fn_unidade_medida(i.nome),
    fn_quantidade_medida(i.nome),
    GREATEST(1, FLOOR(i.qtdMinima * (1.8 + RAND() * 0.4) * i.mult_alta_demanda)),
    GREATEST(1, FLOOR(i.qtdMinima * (1.8 + RAND() * 0.4) * i.mult_alta_demanda)),
    TIMESTAMP(
        tdr.data_dia,
        MAKETIME(
            FLOOR(RAND() * 4) + 6,   -- 6:00 - 9:59
            FLOOR(RAND() * 60),
            FLOOR(RAND() * 60)
        )
    ),
    1
FROM temp_date_range tdr
CROSS JOIN temp_insumos i
CROSS JOIN (
    SELECT idMarca, fkInsumo FROM marca ORDER BY RAND() LIMIT 1
) m_sub
JOIN marca m ON m.idMarca = m_sub.idMarca AND m.fkInsumo = i.idInsumo
WHERE i.rotatividade = 1
    AND MOD(DAY(tdr.data_dia), @BULK_RESTOCK_MAX_GAP) = 0
    AND RAND() < @BULK_RESTOCK_CHANCE;

-- ================================================================
-- 5. LIMPEZA: REMOVER/ZERAR LOTES VENCIDOS
-- ================================================================
IF @DELETE_EXPIRED_LOTS THEN
    SET FOREIGN_KEY_CHECKS = 0;
    DELETE hl FROM historicoLote hl
    JOIN lote l ON l.idLote = hl.fkLote
    WHERE l.dataValidade < DATE_SUB(CURDATE(), INTERVAL @EXPIRE_GRACE_DAYS DAY);
    
    DELETE FROM lote 
    WHERE dataValidade < DATE_SUB(CURDATE(), INTERVAL @EXPIRE_GRACE_DAYS DAY);
    SET FOREIGN_KEY_CHECKS = 1;
ELSE
    UPDATE lote 
    SET quantidadeAtual = 0, ativo = 0 
    WHERE dataValidade < DATE_SUB(CURDATE(), INTERVAL @EXPIRE_GRACE_DAYS DAY);
END IF;

-- ================================================================
-- REPORT
-- ================================================================
SELECT CONCAT(
    '=================================================================',
    '\nRELATÓRIO DE DADOS POPULADOS',
    '\n=================================================================',
    '\nUsuários: ', (SELECT COUNT(*) FROM Usuario),
    '\nClientes: ', (SELECT COUNT(*) FROM cliente),
    '\nFornecedores: ', (SELECT COUNT(*) FROM fornecedor),
    '\nInsumos: ', (SELECT COUNT(*) FROM insumo),
    '\nLotes Ativos: ', (SELECT COUNT(*) FROM lote WHERE ativo = 1),
    '\nHistóricos: ', (SELECT COUNT(*) FROM historicoLote),
    '\nDívidas: ', (SELECT COUNT(*) FROM divida),
    '\nDívidas em Aberto: ', (SELECT COUNT(*) FROM divida WHERE pago = 0),
    '\nBoletos: ', (SELECT COUNT(*) FROM boleto),
    '\nBoletos em Aberto: ', (SELECT COUNT(*) FROM boleto WHERE pago = 0),
    '\n=================================================================',
    '\n✓ Simulação de estoque: ', @START_DATE, ' até ', @END_DATE,
    '\n✓ Consumo diário: ', @RETIRADAS_MIN, '-', @RETIRADAS_MAX, ' operações',
    '\n✓ Reposição: semanal (probabilística)',
    '\n✓ Bulk restock: a cada ', @BULK_RESTOCK_MAX_GAP, ' dias',
    '\n================================================================='
) AS Report;

-- ================================================================
-- LIMPEZA DE TABELAS TEMPORÁRIAS
-- ================================================================
DROP TEMPORARY TABLE IF EXISTS temp_date_range;
DROP TEMPORARY TABLE IF EXISTS temp_insumos;
DROP TEMPORARY TABLE IF EXISTS temp_insumos_alta_demanda;
DROP TEMPORARY TABLE IF EXISTS temp_last_buy;
