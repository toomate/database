USE toomate;

-- ============================================================
-- MOCK DE DADOS - TOOMATE
-- Datas dos lotes são relativas à data atual (CURDATE())
-- ============================================================


-- ------------------------------------------------------------
-- USUÁRIOS
-- Senha: hash SHA-256 de 'senha123'
-- ------------------------------------------------------------
INSERT INTO Usuario (nome, apelido, senha, administrador) VALUES
    ('Carlos Eduardo Silva',  'carlos',  '64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0d7', 1),
    ('Ana Paula Souza',       'ana',     '64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0d7', 0),
    ('Roberto Mendes',        'roberto', '64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0d7', 0);


-- ------------------------------------------------------------
-- CATEGORIAS
-- ------------------------------------------------------------
INSERT INTO categoria (nome, rotatividade) VALUES
    ('Laticínios',             1),
    ('Carnes e Aves',          1),
    ('Grãos e Cereais',        0),
    ('Temperos e Condimentos', 0),
    ('Bebidas',                0);


-- ------------------------------------------------------------
-- FORNECEDORES
-- ------------------------------------------------------------
INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('Laticínios do Vale Ltda',        '(11) 91111-1111', 'https://wa.me/5511911111111'),
    ('Frigorífico Central S.A.',       '(11) 92222-2222', 'https://wa.me/5511922222222'),
    ('Distribuidora Grãos Brasil Ltda','(11) 93333-3333', 'https://wa.me/5511933333333'),
    ('Temperos & Cia Ltda',            '(11) 94444-4444', 'https://wa.me/5511944444444'),
    ('Distribuidora de Bebidas S.A.',  '(11) 95555-5555', 'https://wa.me/5511955555555');


-- ------------------------------------------------------------
-- INSUMOS
-- fkCategoria: 1=Laticínios, 2=Carnes, 3=Grãos, 4=Temperos, 5=Bebidas
-- ------------------------------------------------------------
INSERT INTO insumo (fkCategoria, nome, qtdMinima, unidadeMedida) VALUES
    (1, 'Leite Integral',     10, 'L'),
    (1, 'Queijo Mussarela',    5, 'kg'),
    (2, 'Frango Inteiro',      8, 'kg'),
    (2, 'Carne Bovina Moída', 10, 'kg'),
    (3, 'Arroz Branco',       20, 'kg'),
    (3, 'Feijão Carioca',     15, 'kg'),
    (4, 'Sal Refinado',        5, 'kg'),
    (4, 'Óleo de Soja',        6, 'L'),
    (5, 'Refrigerante 2L',    24, 'un'),
    (5, 'Água Mineral 500ml', 50, 'un');


-- ------------------------------------------------------------
-- MARCAS
-- fkInsumo / fkFornecedor conforme sequência de inserts acima
-- ------------------------------------------------------------
INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    (1,  1, 'Italac'),         -- Leite Integral       / Laticínios do Vale
    (2,  1, 'Polenghi'),       -- Queijo Mussarela     / Laticínios do Vale
    (3,  2, 'Seara'),          -- Frango Inteiro       / Frigorífico Central
    (4,  2, 'Friboi'),         -- Carne Bovina Moída   / Frigorífico Central
    (5,  3, 'Tio João'),       -- Arroz Branco         / Distrib. Grãos Brasil
    (6,  3, 'Camil'),          -- Feijão Carioca       / Distrib. Grãos Brasil
    (7,  4, 'Cisne'),          -- Sal Refinado         / Temperos & Cia
    (8,  4, 'Liza'),           -- Óleo de Soja         / Temperos & Cia
    (9,  5, 'Coca-Cola'),      -- Refrigerante 2L      / Distrib. de Bebidas
    (10, 5, 'Crystal');        -- Água Mineral 500ml   / Distrib. de Bebidas


-- ------------------------------------------------------------
-- LOTES
-- dateEntrada = CURDATE() (data de entrada atual)
-- dataValidade relativa à data atual para cenários variados:
--   - Produtos já vencidos (para testar KPIs de perda)
--   - Produtos vencendo em breve (para alertas)
--   - Produtos com validade normal
-- fkMarca / fkUsuario conforme sequências acima
-- ------------------------------------------------------------
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, quantidadeMedida, dateEntrada, dataValidade) VALUES
    -- Leite Integral (Italac) - vence em 5 dias
    (1, 1, 4.50,  20.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL  5 DAY)),
    -- Queijo Mussarela (Polenghi) - vence em 15 dias
    (2, 2, 38.90,  8.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY)),
    -- Frango Inteiro (Seara) - vence em 3 dias (alerta de perda)
    (3, 1, 12.75, 10.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL  3 DAY)),
    -- Frango Inteiro (Seara) - lote anterior já vencido
    (3, 2,  11.90,  2.0, DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
    -- Carne Bovina Moída (Friboi) - vence em 7 dias
    (4, 1, 29.99, 15.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL  7 DAY)),
    -- Arroz Branco (Tio João) - validade em 12 meses
    (5, 3,  5.49, 30.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    -- Feijão Carioca (Camil) - validade em 10 meses
    (6, 3,  7.20, 25.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    -- Sal Refinado (Cisne) - validade em 24 meses
    (7, 2,  3.10, 10.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 24 MONTH)),
    -- Óleo de Soja (Liza) - validade em 18 meses
    (8, 2,  8.75, 12.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 18 MONTH)),
    -- Refrigerante 2L (Coca-Cola) - validade em 6 meses
    (9, 1, 10.00, 36.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL  6 MONTH)),
    -- Água Mineral 500ml (Crystal) - validade em 2 anos
    (10, 3,  1.20, 60.0, CURDATE(), DATE_ADD(CURDATE(), INTERVAL  2 YEAR));
