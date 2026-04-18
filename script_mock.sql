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
INSERT INTO categoria (nome, rotatividade) VALUES
    ('Laticínios',             1),
    ('Carnes e Aves',          1),
    ('Grãos e Cereais',        0),
    ('Temperos e Condimentos', 0),
    ('Bebidas',                0);
INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('Laticínios do Vale Ltda',        CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Frigorífico Central S.A.',       CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Distribuidora Grãos Brasil Ltda',CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Temperos & Cia Ltda',            CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Distribuidora de Bebidas S.A.',  CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0')));
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
    (5, 'Água Mineral 500ml', 50, 'un'),
    (1, 'Creme de Leite',       8, 'L'),
    (1, 'Manteiga',             6, 'kg'),
    (1, 'Iogurte Natural',     12, 'L'),
    (1, 'Requeijao Cremoso',    5, 'kg'),
    (1, 'Leite Condensado',    10, 'un'),
    (1, 'Queijo Prato',         7, 'kg'),
    (2, 'Peito de Frango',      9, 'kg'),
    (2, 'Coxa e Sobrecoxa',     9, 'kg'),
    (2, 'Carne Suina',          8, 'kg'),
    (2, 'Linguica Toscana',     7, 'kg'),
    (2, 'Bacon',                6, 'kg'),
    (2, 'File de Tilapia',      6, 'kg'),
    (3, 'Acucar Refinado',     18, 'kg'),
    (3, 'Farinha de Trigo',    16, 'kg'),
    (3, 'Macarrao Espaguete',  20, 'un'),
    (3, 'Lentilha',            12, 'kg'),
    (3, 'Grao de Bico',        10, 'kg'),
    (3, 'Milho Verde',         24, 'un'),
    (4, 'Pimenta do Reino',     4, 'kg'),
    (4, 'Colorau',              4, 'kg'),
    (4, 'Acafrao',              3, 'kg'),
    (4, 'Vinagre Alcool',       8, 'L'),
    (4, 'Molho de Tomate',     20, 'un'),
    (4, 'Shoyu',                6, 'L'),
    (5, 'Suco de Laranja 1L',  18, 'un'),
    (5, 'Suco de Uva 1L',      18, 'un'),
    (5, 'Cha Gelado 1.5L',     15, 'un'),
    (5, 'Energetico 269ml',    30, 'un'),
    (5, 'Agua com Gas 500ml',  40, 'un'),
    (5, 'Isotonico 500ml',     24, 'un');
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
INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    (11, 1, 'Piracanjuba'),
    (12, 1, 'Aviacao'),
    (13, 1, 'Nestle'),
    (14, 1, 'Vigor'),
    (15, 1, 'MoCa'),
    (16, 1, 'Tirolez'),
    (17, 2, 'Sadia'),
    (18, 2, 'Perdigao'),
    (19, 2, 'Aurora'),
    (20, 2, 'Seara Gourmet'),
    (21, 2, 'Pif Paf'),
    (22, 2, 'Copacol'),
    (23, 3, 'Uniao'),
    (24, 3, 'Dona Benta'),
    (25, 3, 'Renata'),
    (26, 3, 'Kicaldo'),
    (27, 3, 'Yoki'),
    (28, 3, 'Quero'),
    (29, 4, 'Kitano'),
    (30, 4, 'Sinha'),
    (31, 4, 'Bombay'),
    (32, 4, 'Castelo'),
    (33, 4, 'Elefante'),
    (34, 4, 'Kikkoman'),
    (35, 5, 'Del Valle'),
    (36, 5, 'Aurora Suco'),
    (37, 5, 'Leao Fuze'),
    (38, 5, 'Red Bull'),
    (39, 5, 'Perrier'),
    (40, 5, 'Gatorade');
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, quantidadeMedida, dateEntrada, dataValidade) VALUES
    (1, 1, ROUND(3.50 + RAND() * 2.00, 2),  ROUND(15 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  5 DAY)),
    (2, 2, ROUND(35.00 + RAND() * 8.00, 2),  ROUND(5 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY)),
    (3, 1, ROUND(11.00 + RAND() * 3.50, 2), ROUND(8 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  3 DAY)),
    (3, 2,  ROUND(10.00 + RAND() * 3.00, 2),  ROUND(1 + RAND() * 4, 1), DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
    (4, 1, ROUND(27.00 + RAND() * 6.00, 2), ROUND(12 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  7 DAY)),
    (5, 3,  ROUND(4.99 + RAND() * 1.50, 2), ROUND(25 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    (6, 3,  ROUND(6.50 + RAND() * 1.80, 2), ROUND(20 + RAND() * 15, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (7, 2,  ROUND(2.50 + RAND() * 1.20, 2), ROUND(8 + RAND() * 6, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 24 MONTH)),
    (8, 2,  ROUND(7.50 + RAND() * 3.00, 2), ROUND(10 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 18 MONTH)),
    (9, 1, ROUND(8.50 + RAND() * 3.00, 2), ROUND(30 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  6 MONTH)),
    (10, 3,  ROUND(0.90 + RAND() * 0.80, 2), ROUND(50 + RAND() * 30, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  2 YEAR));
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, quantidadeMedida, dateEntrada, dataValidade) VALUES
    (11, 1, ROUND(4.00 + RAND() * 2.00, 2),  ROUND(10 + RAND() * 15, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 DAY)),
    (12, 2, ROUND(18.00 + RAND() * 6.00, 2), ROUND(6 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 40 DAY)),
    (13, 3, ROUND(6.00 + RAND() * 2.00, 2),  ROUND(12 + RAND() * 18, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 25 DAY)),
    (14, 1, ROUND(14.00 + RAND() * 4.00, 2), ROUND(5 + RAND() * 7, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 35 DAY)),
    (15, 2, ROUND(5.50 + RAND() * 1.50, 2),  ROUND(10 + RAND() * 12, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 8 MONTH)),
    (16, 3, ROUND(32.00 + RAND() * 8.00, 2), ROUND(4 + RAND() * 5, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 28 DAY)),
    (17, 1, ROUND(12.00 + RAND() * 3.00, 2), ROUND(8 + RAND() * 10, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 4 DAY)),
    (18, 2, ROUND(11.00 + RAND() * 3.00, 2), ROUND(8 + RAND() * 9, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 DAY)),
    (19, 3, ROUND(23.00 + RAND() * 7.00, 2), ROUND(6 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 9 DAY)),
    (20, 1, ROUND(17.00 + RAND() * 5.00, 2), ROUND(7 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 DAY)),
    (21, 2, ROUND(28.00 + RAND() * 8.00, 2), ROUND(4 + RAND() * 5, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 DAY)),
    (22, 3, ROUND(31.00 + RAND() * 9.00, 2), ROUND(5 + RAND() * 6, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 DAY)),
    (23, 1, ROUND(4.50 + RAND() * 1.50, 2),  ROUND(20 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    (24, 2, ROUND(5.00 + RAND() * 1.60, 2),  ROUND(18 + RAND() * 18, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (25, 3, ROUND(3.20 + RAND() * 1.20, 2),  ROUND(25 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    (26, 1, ROUND(8.00 + RAND() * 2.00, 2),  ROUND(10 + RAND() * 12, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (27, 2, ROUND(11.00 + RAND() * 3.00, 2), ROUND(9 + RAND() * 10, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    (28, 3, ROUND(2.80 + RAND() * 1.10, 2),  ROUND(22 + RAND() * 18, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    (29, 1, ROUND(52.00 + RAND() * 15.00, 2), ROUND(1 + RAND() * 2, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 24 MONTH)),
    (30, 2, ROUND(6.00 + RAND() * 2.00, 2),   ROUND(6 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 18 MONTH)),
    (31, 3, ROUND(35.00 + RAND() * 10.00, 2), ROUND(2 + RAND() * 3, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 MONTH)),
    (32, 1, ROUND(3.80 + RAND() * 1.30, 2),   ROUND(8 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 16 MONTH)),
    (33, 2, ROUND(4.20 + RAND() * 1.40, 2),   ROUND(12 + RAND() * 10, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    (34, 3, ROUND(9.00 + RAND() * 3.00, 2),   ROUND(7 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (35, 1, ROUND(7.50 + RAND() * 2.50, 2),   ROUND(18 + RAND() * 18, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    (36, 2, ROUND(8.00 + RAND() * 2.70, 2),   ROUND(18 + RAND() * 16, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    (37, 3, ROUND(6.20 + RAND() * 2.20, 2),   ROUND(15 + RAND() * 14, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    (38, 1, ROUND(9.50 + RAND() * 3.50, 2),   ROUND(20 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    (39, 2, ROUND(2.10 + RAND() * 1.20, 2),   ROUND(25 + RAND() * 20, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 YEAR)),
    (40, 3, ROUND(4.80 + RAND() * 1.80, 2),   ROUND(20 + RAND() * 18, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (5,  1, ROUND(5.20 + RAND() * 1.50, 2),   ROUND(18 + RAND() * 15, 1), DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 3 DAY)),
    (18, 2, ROUND(10.50 + RAND() * 2.50, 2),  ROUND(6 + RAND() * 7, 1), DATE_SUB(CURDATE(), INTERVAL 8 DAY), DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
    (27, 3, ROUND(10.80 + RAND() * 2.80, 2),  ROUND(8 + RAND() * 8, 1), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 13 MONTH));
INSERT INTO boleto (descricao, categoria, pago, dataVencimento, dataPagamento, valor, fkFornecedor) VALUES
    ('Boleto energia - Janeiro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Janeiro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  19 DAY), NULL,                                                                      ROUND(700 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Fevereiro',       'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(420 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Fevereiro',    'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  48 DAY), NULL,                                                                      ROUND(720 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Marco',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(440 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Marco',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  78 DAY), NULL,                                                                      ROUND(750 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Abril',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), INTERVAL FLOOR(1 + RAND() * 3) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Abril',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 109 DAY), NULL,                                                                      ROUND(770 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Maio',            'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(430 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Maio',         'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 140 DAY), NULL,                                                                      ROUND(790 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Junho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(450 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Junho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 170 DAY), NULL,                                                                      ROUND(800 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Julho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(460 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Julho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 201 DAY), NULL,                                                                      ROUND(810 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Agosto',          'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(470 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Agosto',       'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 231 DAY), NULL,                                                                      ROUND(820 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Setembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(480 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Setembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 262 DAY), NULL,                                                                      ROUND(830 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Outubro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(490 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Outubro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 292 DAY), NULL,                                                                      ROUND(850 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Novembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(500 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Novembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 323 DAY), NULL,                                                                      ROUND(860 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Dezembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(510 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Dezembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 353 DAY), NULL,                                                                      ROUND(880 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1);
INSERT INTO cliente (nome, telefone, cep, logradouro, bairro) VALUES
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Joao Pedro Lima' WHEN 1 THEN 'João Silva Santos' WHEN 2 THEN 'João Oliveira' WHEN 3 THEN 'João da Costa' ELSE 'João Ferreira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua das Palmeiras, 120', 'Centro'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Mariana Costa Alves' WHEN 1 THEN 'Mariana Silva' WHEN 2 THEN 'Mariana Oliveira' WHEN 3 THEN 'Mariana Santos' ELSE 'Mariana Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Av. Paulista, 1500', 'Bela Vista'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Rafael Souza Martins' WHEN 1 THEN 'Rafael Costa' WHEN 2 THEN 'Rafael Silva' WHEN 3 THEN 'Rafael Oliveira' ELSE 'Rafael Santos' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua do Carmo, 45', 'Mooca'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Patricia Nunes Rocha' WHEN 1 THEN 'Patricia Silva' WHEN 2 THEN 'Patricia Costa' WHEN 3 THEN 'Patricia Santos' ELSE 'Patricia Oliveira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Voluntarios, 300', 'Santana'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Bruno Henrique Santos' WHEN 1 THEN 'Bruno Silva' WHEN 2 THEN 'Bruno Costa' WHEN 3 THEN 'Bruno Oliveira' ELSE 'Bruno Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Clovis, 88', 'Lapa');
INSERT INTO divida (valor, dataCompra, dataPagamento, pedido, pago, fkCliente) VALUES
    (ROUND(50 + RAND() * 100, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(10 + RAND() * 30) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 1),
    (ROUND(20 + RAND() * 80, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), NULL, CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 1),
    (ROUND(80 + RAND() * 120, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(8 + RAND() * 25) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(30 + RAND() * 80, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 5) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(100 + RAND() * 150, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(30 + RAND() * 60) DAY), NULL, CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(25 + RAND() * 75, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY), NULL, CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(60 + RAND() * 100, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 4),
    (ROUND(70 + RAND() * 120, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(3 + RAND() * 15) DAY), NULL, CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 4),
    (ROUND(130 + RAND() * 180, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(40 + RAND() * 80) DAY), NULL, CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 5),
    (ROUND(40 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 10) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 5);