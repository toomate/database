use toomate;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE arquivoRelacionamento;
TRUNCATE TABLE arquivo;
TRUNCATE TABLE rotinaInsumo;
TRUNCATE TABLE rotina;
TRUNCATE TABLE lote;
TRUNCATE TABLE marca;
TRUNCATE TABLE divida;
TRUNCATE TABLE cliente;
TRUNCATE TABLE boleto;
TRUNCATE TABLE insumo;
TRUNCATE TABLE fornecedor;
TRUNCATE TABLE categoria;
TRUNCATE TABLE Usuario;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Usuario (nome, apelido, senha, administrador) VALUES
    ('Carlos Eduardo Silva',  'carlos',  'senha123', 1),
    ('Ana Paula Souza',       'ana',     'senha123', 0),
    ('Roberto Mendes',        'roberto', 'senha123', 0);

INSERT INTO categoria (nome) VALUES
    ('Proteínas'),               -- ID 1
    ('Pescados'),                -- ID 2
    ('Hortifruti'),              -- ID 3
    ('Laticínios'),              -- ID 4
    ('Frios e Embutidos'),       -- ID 5
    ('Grãos e Secos'),           -- ID 6
    ('Temperos e Condimentos'),  -- ID 7
    ('Óleos e Gorduras'),        -- ID 8
    ('Bebidas');                 -- ID 9

INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('Laticínios do Vale Ltda',         '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Frigorífico Central S.A.',        '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora Grãos Brasil Ltda', '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Temperos & Cia Ltda',             '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora de Bebidas S.A.',   '(11) 5897-2493', 'https://wa.me/551158972493');

INSERT INTO insumo (fkCategoria, nome, qtdMinima, rotatividade) VALUES
    -- 1 Proteínas
    (1, 'Peito de Frango',        6, 1),  -- id 1
    (1, 'Carne Bovina Moída',     5, 1),  -- id 2
    (1, 'Carne Suína',            4, 1),  -- id 3

    -- 2 Pescados
    (2, 'Filé de Tilápia',        4, 1),  -- id 4
    (2, 'Sardinha',               6, 0),  -- id 5

    -- 3 Hortifruti
    (3, 'Cebola',                 8, 1),  -- id 6
    (3, 'Alho',                   3, 1),  -- id 7
    (3, 'Tomate',                 8, 1),  -- id 8

    -- 4 Laticínios
    (4, 'Leite Integral',        12, 1),  -- id 9
    (4, 'Queijo Mussarela',       4, 1),  -- id 10
    (4, 'Manteiga',               3, 1),  -- id 11

    -- 5 Frios e Embutidos
    (5, 'Bacon',                  3, 1),  -- id 12
    (5, 'Linguiça Toscana',       4, 1),  -- id 13
    (5, 'Presunto',               3, 1),  -- id 14

    -- 6 Grãos e Secos
    (6, 'Arroz Branco',          10, 0),  -- id 15
    (6, 'Feijão Carioca',         8, 0),  -- id 16
    (6, 'Farinha de Trigo',       6, 0),  -- id 17
    (6, 'Macarrão Espaguete',     8, 0),  -- id 18

    -- 7 Temperos e Condimentos
    (7, 'Sal Refinado',           3, 0),  -- id 19
    (7, 'Pimenta do Reino',       2, 0),  -- id 20
    (7, 'Molho de Tomate',       10, 1),  -- id 21
    (7, 'Vinagre',                2, 0),  -- id 22

    -- 8 Óleos e Gorduras
    (8, 'Óleo de Soja',           4, 0),  -- id 23
    (8, 'Azeite',                 2, 0),  -- id 24

    -- 9 Bebidas
    (9, 'Refrigerante',          18, 0),  -- id 25
    (9, 'Água Mineral',          36, 0),  -- id 26
    (9, 'Suco de Laranja',       12, 1);  -- id 27 -- ID 40

INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    -- id 1..?
    (1,  2, 'Sadia'),
    (1,  2, 'Seara'),

    (2,  2, 'Friboi'),
    (2,  2, 'Swift'),

    (3,  2, 'Aurora'),
    (3,  2, 'Perdigão'),

    (4,  2, 'Copacol'),
    (4,  2, 'Qualitá'),

    (5,  2, 'Coqueiro'),
    (5,  2, 'Gomes da Costa'),

    (6,  3, 'Hortifruti Central'),
    (6,  3, 'Sítio do João'),

    (7,  3, 'Hortifruti Central'),
    (7,  3, 'Sítio do João'),

    (8,  3, 'Hortifruti Central'),
    (8,  3, 'Sítio do João'),

    (9,  1, 'Italac'),
    (9,  1, 'Piracanjuba'),

    (10, 1, 'Polenghi'),
    (10, 1, 'Tirolez'),

    (11, 1, 'Aviação'),
    (11, 1, 'Vigor'),

    (12, 2, 'Seara'),
    (12, 2, 'Perdigão'),

    (13, 2, 'Aurora'),
    (13, 2, 'Seara'),

    (14, 1, 'Sadia'),
    (14, 1, 'Perdigão'),

    (15, 3, 'Camil'),
    (15, 3, 'Tio João'),

    (16, 3, 'Camil'),
    (16, 3, 'Kicaldo'),

    (17, 3, 'Dona Benta'),
    (17, 3, 'Sol'),

    (18, 3, 'Renata'),
    (18, 3, 'Adria'),

    (19, 4, 'Cisne'),
    (19, 4, 'Qualitá'),

    (20, 4, 'Kitano'),
    (20, 4, 'Bombay'),

    (21, 4, 'Pomarola'),
    (21, 4, 'Elefante'),

    (22, 4, 'Castelo'),
    (22, 4, 'Qualitá'),

    (23, 4, 'Liza'),
    (23, 4, 'Soya'),

    (24, 4, 'Gallo'),
    (24, 4, 'Andorinha'),

    (25, 5, 'Coca-Cola'),
    (25, 5, 'Antarctica'),

    (26, 5, 'Crystal'),
    (26, 5, 'Minalba'),

    (27, 5, 'Del Valle'),
    (27, 5, 'Maguary'); -- ID 40

-- 1 lote para cada marca "A" (primeira marca de cada insumo)
INSERT INTO lote (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada) VALUES
    -- Proteínas (unidadeMedida/kg)
    (1,  1, DATE_ADD(CURDATE(), INTERVAL  5 DAY),  15.90, 'kg', 1,  12, 10, NOW()), -- Peito de Frango (Sadia)
    (3,  2, DATE_ADD(CURDATE(), INTERVAL  6 DAY),  32.90, 'kg', 1,  10,  7, NOW()), -- Carne Moída (Friboi)
    (5,  1, DATE_ADD(CURDATE(), INTERVAL  7 DAY),  28.90, 'kg', 1,   8,  6, NOW()), -- Carne Suína (Aurora)

    -- Pescados
    (7,  3, DATE_ADD(CURDATE(), INTERVAL  4 DAY),  34.90, 'kg', 1,   6,  5, NOW()), -- Tilápia (Copacol)
    (9,  3, DATE_ADD(CURDATE(), INTERVAL 10 DAY),  10.90, 'un', 1,  24, 18, NOW()), -- Sardinha (Coqueiro)

    -- Hortifruti
    (11, 2, DATE_ADD(CURDATE(), INTERVAL 12 DAY),   6.50, 'kg', 1,  10,  8, NOW()), -- Cebola
    (13, 2, DATE_ADD(CURDATE(), INTERVAL 20 DAY),  22.00, 'kg', 1,   3,  2, NOW()), -- Alho
    (15, 2, DATE_ADD(CURDATE(), INTERVAL  7 DAY),   8.90, 'kg', 1,   8,  6, NOW()), -- Tomate

    -- Laticínios
    (17, 1, DATE_ADD(CURDATE(), INTERVAL  8 DAY),   5.49, 'L',  1,  18, 14, NOW()), -- Leite (Italac)
    (19, 1, DATE_ADD(CURDATE(), INTERVAL 12 DAY),  39.90, 'kg', 1,   6,  4, NOW()), -- Mussarela (Polenghi)
    (21, 1, DATE_ADD(CURDATE(), INTERVAL 25 DAY), 17.90, 'g', 200, 12, 9, NOW()), -- Manteiga (Aviação) - tablete 200g

    -- Frios/Embutidos
    (23, 1, DATE_ADD(CURDATE(), INTERVAL 15 DAY),  29.90, 'kg', 1,   5,  4, NOW()), -- Bacon
    (25, 2, DATE_ADD(CURDATE(), INTERVAL 12 DAY),  19.90, 'kg', 1,   6,  5, NOW()), -- Linguiça
    (27, 2, DATE_ADD(CURDATE(), INTERVAL 10 DAY),  18.50, 'kg', 1,   4,  3, NOW()), -- Presunto

    -- Grãos/Secos
    (29, 3, DATE_ADD(CURDATE(), INTERVAL 10 MONTH), 27.90, 'kg', 5,   4,  4, NOW()), -- Arroz (pacote 5kg) qtd=4 pacotes
    (31, 3, DATE_ADD(CURDATE(), INTERVAL  9 MONTH),  8.90, 'kg', 1,   8,  7, NOW()), -- Feijão
    (33, 3, DATE_ADD(CURDATE(), INTERVAL  8 MONTH),  6.90, 'kg', 1,   6,  5, NOW()), -- Farinha trigo
    (35, 3, DATE_ADD(CURDATE(), INTERVAL  9 MONTH),  4.90, 'un', 500, 10,  9, NOW()), -- Macarrão (pacote 500g)

    -- Temperos/Condimentos
    (37, 2, DATE_ADD(CURDATE(), INTERVAL 18 MONTH),  3.20, 'kg', 1,   2,  2, NOW()), -- Sal
    (39, 2, DATE_ADD(CURDATE(), INTERVAL 24 MONTH),  6.50, 'g',  50,  6,  5, NOW()), -- Pimenta (pote 50g)
    (41, 2, DATE_ADD(CURDATE(), INTERVAL  6 MONTH),  2.90, 'g',  340, 18, 14, NOW()), -- Molho de tomate (sachê/lata 340g)
    (43, 2, DATE_ADD(CURDATE(), INTERVAL 18 MONTH),  4.90, 'ml', 750,  4,  3, NOW()), -- Vinagre (750ml)

    -- Óleos/Gorduras
    (45, 1, DATE_ADD(CURDATE(), INTERVAL 14 MONTH),  7.90, 'ml', 900,  6,  5, NOW()), -- Óleo (900ml)
    (47, 1, DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 29.90, 'ml', 500,  3,  2, NOW()), -- Azeite (500ml)

    -- Bebidas
    (49, 3, DATE_ADD(CURDATE(), INTERVAL  4 MONTH),  8.90, 'L',    2, 24, 20, NOW()), -- Refrigerante (2L)
    (51, 3, DATE_ADD(CURDATE(), INTERVAL 12 MONTH),  1.20, 'ml', 500, 48, 40, NOW()), -- Água (500ml)
    (53, 3, DATE_ADD(CURDATE(), INTERVAL  3 MONTH),  7.90, 'L',    1, 18, 15, NOW()); -- Suco (1L)

INSERT INTO lote (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada) VALUES
    -- Peito de frango (Seara) - outro lote
    (2,  2, DATE_ADD(CURDATE(), INTERVAL  2 DAY),  15.50, 'kg', 1,  8, 6, DATE_SUB(NOW(), INTERVAL 2 DAY)),

    -- Carne moída (Swift)
    (4,  3, DATE_ADD(CURDATE(), INTERVAL  3 DAY),  33.90, 'kg', 1,  6, 4, DATE_SUB(NOW(), INTERVAL 1 DAY)),

    -- Tilápia (Qualitá)
    (8,  1, DATE_ADD(CURDATE(), INTERVAL  2 DAY),  33.50, 'kg', 1,  4, 3, DATE_SUB(NOW(), INTERVAL 1 DAY)),

    -- Leite (Piracanjuba)
    (18, 1, DATE_ADD(CURDATE(), INTERVAL  5 DAY),   5.29, 'L',  1, 12, 9, DATE_SUB(NOW(), INTERVAL 3 DAY)),

    -- Mussarela (Tirolez)
    (20, 2, DATE_ADD(CURDATE(), INTERVAL  9 DAY),  41.90, 'kg', 1,  4, 3, DATE_SUB(NOW(), INTERVAL 2 DAY)),

    -- Molho de tomate (Elefante) - outro lote
    (42, 3, DATE_ADD(CURDATE(), INTERVAL  5 MONTH), 3.10, 'g', 340, 12, 9, DATE_SUB(NOW(), INTERVAL 10 DAY)),

    -- Refrigerante (Antarctica)
    (50, 3, DATE_ADD(CURDATE(), INTERVAL  3 MONTH), 7.90, 'L',   2, 12, 8, DATE_SUB(NOW(), INTERVAL 5 DAY)),

    -- Água (Minalba)
    (52, 2, DATE_ADD(CURDATE(), INTERVAL 11 MONTH), 1.10, 'ml', 500, 24, 18, DATE_SUB(NOW(), INTERVAL 15 DAY));

-- BLOCO DE LOTES 3: Terceiro lote para produtos de altíssima saída em restaurantes
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada, dataValidade) VALUES
    -- Arroz (ex: pacotes de 5kg) - alta saída, mas em volumes plausíveis
    (5,  1, ROUND(25.30 + RAND() * 3.00, 2), 'kg', 5,   FLOOR(8  + RAND() * 8),  FLOOR(4  + RAND() * 6),  NOW(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),

    -- Feijão (1kg)
    (6,  2, ROUND(6.40  + RAND() * 1.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 10), FLOOR(6  + RAND() * 8),  NOW(), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),

    -- Refrigerante (2L)
    (9,  3, ROUND(8.60  + RAND() * 1.50, 2), 'L',  2,   FLOOR(12 + RAND() * 12), FLOOR(6  + RAND() * 10), NOW(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),

    -- Peito de Frango (1kg)
    (16, 1, ROUND(12.20 + RAND() * 2.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 10), FLOOR(5  + RAND() * 8),  NOW(), DATE_ADD(CURDATE(), INTERVAL 6 DAY)),

    -- Macarrão (pacote 500g)
    (24, 2, ROUND(3.30  + RAND() * 1.00, 2), 'g',  500, FLOOR(12 + RAND() * 12), FLOOR(6  + RAND() * 10), NOW(), DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),

    -- Cebola (ex: saco de 20kg) - restaurante pequeno não teria 80 sacos; coloquei baixo
    (39, 3, ROUND(82.90 + RAND() * 5.00, 2), 'kg', 20,  FLOOR(2  + RAND() * 3),  FLOOR(1  + RAND() * 2),  NOW(), DATE_ADD(CURDATE(), INTERVAL 25 DAY));


INSERT INTO boleto (descricao, categoria, pago, dataVencimento, dataPagamento, valor, fkFornecedor) VALUES
    ('Boleto energia - Janeiro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Janeiro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  19 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(700 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Fevereiro',       'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(420 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Fevereiro',    'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  48 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(720 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Marco',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(440 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Marco',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  78 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(750 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Abril',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), INTERVAL FLOOR(1 + RAND() * 3) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Abril',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 109 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(770 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Maio',            'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(430 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Maio',         'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 140 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(790 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Junho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(450 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Junho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 170 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(800 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Julho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(460 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Julho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 201 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(810 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Agosto',          'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(470 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Agosto',       'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 231 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(820 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Setembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(480 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Setembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 262 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(830 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Outubro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(490 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Outubro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 292 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(850 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Novembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(500 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Novembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 323 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(860 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Dezembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(510 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Dezembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 353 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(880 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1);

INSERT INTO cliente (nome, telefone, cep, logradouro, bairro) VALUES
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Joao Pedro Lima' WHEN 1 THEN 'Anselmo Silva Santos' WHEN 2 THEN 'João Oliveira' WHEN 3 THEN 'Carlos da Costa' ELSE 'Felipe Ferreira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua das Palmeiras, 120', 'Centro'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Mariana Costa Alves' WHEN 1 THEN 'Clara Silva' WHEN 2 THEN 'Mariana Oliveira' WHEN 3 THEN 'Beatriz Santos' ELSE 'Mariana Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Av. Paulista, 1500', 'Bela Vista'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Rafael Souza Martins' WHEN 1 THEN 'Rafael Costa' WHEN 2 THEN 'Lucas Silva' WHEN 3 THEN 'Thiago Oliveira' ELSE 'Rafael Santos' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua do Carmo, 45', 'Mooca'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Patricia Nunes Rocha' WHEN 1 THEN 'Patricia Silva' WHEN 2 THEN 'Fernanda Costa' WHEN 3 THEN 'Patricia Santos' ELSE 'Aline Oliveira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Voluntarios, 300', 'Santana'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Bruno Henrique Santos' WHEN 1 THEN 'Bruno Silva' WHEN 2 THEN 'Rodrigo Costa' WHEN 3 THEN 'Bruno Oliveira' ELSE 'Ricardo Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Clovis, 88', 'Lapa');

INSERT INTO divida (valor, dataCompra, dataPagamento, pedido, pago, fkCliente) VALUES
    (ROUND(50 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(10 + RAND() * 30) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 1),
    (ROUND(20 + RAND() * 80, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 1),
    (ROUND(80 + RAND() * 120, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(8 + RAND() * 25) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(30 + RAND() * 80, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 5) DAY),  CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(100 + RAND() * 150, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(30 + RAND() * 60) DAY), '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(25 + RAND() * 75, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(60 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 4),
    (ROUND(70 + RAND() * 120, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(3 + RAND() * 15) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 4),
    (ROUND(130 + RAND() * 180, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(40 + RAND() * 80) DAY), '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 5),
    (ROUND(40 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 10) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 5);