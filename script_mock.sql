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
    ('Carlos Eduardo Silva',  'carlos',  'senha123', 1),
    ('Ana Paula Souza',       'ana',     'senha123', 0),
    ('Roberto Mendes',        'roberto', 'senha123', 0);


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


-- ------------------------------------------------------------
-- BOLETOS
-- 2 boletos por mes do ano atual:
--   - 1 pago (pago = 1, com dataPagamento)
--   - 1 nao pago (pago = 0, sem dataPagamento)
-- fkFornecedor distribuido entre os fornecedores cadastrados (1..5)
-- ------------------------------------------------------------
INSERT INTO boleto (descricao, categoria, pago, dataVencimento, dataPagamento, valor, fkFornecedor) VALUES
    -- Janeiro
    ('Boleto energia - Janeiro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), INTERVAL 2 DAY), 450.00, 1),
    ('Boleto fornecedor - Janeiro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  19 DAY), NULL,                                                                      780.00, 2),

    -- Fevereiro
    ('Boleto energia - Fevereiro',       'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), INTERVAL 3 DAY), 460.00, 3),
    ('Boleto fornecedor - Fevereiro',    'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  48 DAY), NULL,                                                                      790.00, 4),

    -- Marco
    ('Boleto energia - Marco',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), INTERVAL 2 DAY), 470.00, 5),
    ('Boleto fornecedor - Marco',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  78 DAY), NULL,                                                                      810.00, 1),

    -- Abril
    ('Boleto energia - Abril',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), INTERVAL 1 DAY), 440.00, 2),
    ('Boleto fornecedor - Abril',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 109 DAY), NULL,                                                                      830.00, 3),

    -- Maio
    ('Boleto energia - Maio',            'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), INTERVAL 2 DAY), 455.00, 4),
    ('Boleto fornecedor - Maio',         'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 140 DAY), NULL,                                                                      845.00, 5),

    -- Junho
    ('Boleto energia - Junho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), INTERVAL 3 DAY), 465.00, 1),
    ('Boleto fornecedor - Junho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 170 DAY), NULL,                                                                      860.00, 2),

    -- Julho
    ('Boleto energia - Julho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), INTERVAL 2 DAY), 480.00, 3),
    ('Boleto fornecedor - Julho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 201 DAY), NULL,                                                                      875.00, 4),

    -- Agosto
    ('Boleto energia - Agosto',          'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), INTERVAL 2 DAY), 490.00, 5),
    ('Boleto fornecedor - Agosto',       'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 231 DAY), NULL,                                                                      890.00, 1),

    -- Setembro
    ('Boleto energia - Setembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), INTERVAL 2 DAY), 500.00, 2),
    ('Boleto fornecedor - Setembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 262 DAY), NULL,                                                                      910.00, 3),

    -- Outubro
    ('Boleto energia - Outubro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), INTERVAL 3 DAY), 510.00, 4),
    ('Boleto fornecedor - Outubro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 292 DAY), NULL,                                                                      925.00, 5),

    -- Novembro
    ('Boleto energia - Novembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), INTERVAL 2 DAY), 520.00, 1),
    ('Boleto fornecedor - Novembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 323 DAY), NULL,                                                                      940.00, 2),

    -- Dezembro
    ('Boleto energia - Dezembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), INTERVAL 2 DAY), 530.00, 3),
    ('Boleto fornecedor - Dezembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 353 DAY), NULL,                                                                      960.00, 4);


-- ------------------------------------------------------------
-- FIADO (CLIENTES E DIVIDAS)
-- Cenarios para testes:
--   - dividas pagas (com dataPagamento)
--   - dividas em aberto
--   - dividas atrasadas (em aberto e dataCompra antiga)
-- ------------------------------------------------------------
INSERT INTO cliente (nome, telefone, cep, logradouro, bairro) VALUES
    ('Joao Pedro Lima',       '(11) 98888-1111', '01001-000', 'Rua das Palmeiras, 120', 'Centro'),
    ('Mariana Costa Alves',   '(11) 97777-2222', '04567-120', 'Av. Paulista, 1500',      'Bela Vista'),
    ('Rafael Souza Martins',  '(11) 96666-3333', '03321-090', 'Rua do Carmo, 45',        'Mooca'),
    ('Patricia Nunes Rocha',  '(11) 95555-4444', '02021-010', 'Rua Voluntarios, 300',    'Santana'),
    ('Bruno Henrique Santos', '(11) 94444-5555', '05010-030', 'Rua Clovis, 88',          'Lapa');

INSERT INTO divida (valor, dataCompra, dataPagamento, pedido, pago, fkCliente) VALUES
    -- Cliente 1: uma paga e uma em aberto
    (58.90, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 17 DAY), 'PF-1001', 1, 1),
    (34.50, DATE_SUB(CURDATE(), INTERVAL  6 DAY), NULL,                                  'PF-1027', 0, 1),

    -- Cliente 2: historico de pagamento em dia
    (92.30, DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'PF-1014', 1, 2),
    (46.70, DATE_SUB(CURDATE(), INTERVAL  4 DAY), DATE_SUB(CURDATE(), INTERVAL  1 DAY), 'PF-1033', 1, 2),

    -- Cliente 3: uma atrasada e uma recente em aberto
    (121.40, DATE_SUB(CURDATE(), INTERVAL 45 DAY), NULL,                                 'PF-0972', 0, 3),
    (39.90,  DATE_SUB(CURDATE(), INTERVAL  3 DAY), NULL,                                 'PF-1040', 0, 3),

    -- Cliente 4: mix de pago e aberto
    (67.80, DATE_SUB(CURDATE(), INTERVAL 12 DAY), DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'PF-1020', 1, 4),
    (83.20, DATE_SUB(CURDATE(), INTERVAL  8 DAY), NULL,                                  'PF-1029', 0, 4),

    -- Cliente 5: uma muito antiga em aberto (atrasada)
    (149.90, DATE_SUB(CURDATE(), INTERVAL 70 DAY), NULL,                                 'PF-0911', 0, 5),
    (55.60,  DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(CURDATE(), INTERVAL  6 DAY), 'PF-1022', 1, 5);
