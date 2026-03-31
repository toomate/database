use toomate;
INSERT INTO Usuario (nome, apelido, senha, administrador) VALUES
    ('Carlos Eduardo Silva',  'carlos',  'senha123', 1),
    ('Ana Paula Souza',       'ana',     'senha123', 0),
    ('Roberto Mendes',        'roberto', 'senha123', 0);
INSERT INTO categoria (nome, rotatividade) VALUES
    ('LaticÃ­nios',             1),
    ('Carnes e Aves',          1),
    ('GrÃ£os e Cereais',        0),
    ('Temperos e Condimentos', 0),
    ('Bebidas',                0);
INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('LaticÃ­nios do Vale Ltda',        CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('FrigorÃ­fico Central S.A.',       CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Distribuidora GrÃ£os Brasil Ltda',CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Temperos & Cia Ltda',            CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0'))),
    ('Distribuidora de Bebidas S.A.',  CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), CONCAT('https://wa.me/5511', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), LPAD(FLOOR(RAND() * 10000), 4, '0')));
INSERT INTO insumo (fkCategoria, nome, qtdMinima, unidadeMedida) VALUES
    (1, 'Leite Integral',     10, 'L'),
    (1, 'Queijo Mussarela',    5, 'kg'),
    (2, 'Frango Inteiro',      8, 'kg'),
    (2, 'Carne Bovina MoÃ­da', 10, 'kg'),
    (3, 'Arroz Branco',       20, 'kg'),
    (3, 'FeijÃ£o Carioca',     15, 'kg'),
    (4, 'Sal Refinado',        5, 'kg'),
    (4, 'Ã“leo de Soja',        6, 'L'),
    (5, 'Refrigerante 2L',    24, 'un'),
    (5, 'Ãgua Mineral 500ml', 50, 'un');
INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    (1,  1, 'Italac'),         -- Leite Integral       / LaticÃ­nios do Vale
    (2,  1, 'Polenghi'),       -- Queijo Mussarela     / LaticÃ­nios do Vale
    (3,  2, 'Seara'),          -- Frango Inteiro       / FrigorÃ­fico Central
    (4,  2, 'Friboi'),         -- Carne Bovina MoÃ­da   / FrigorÃ­fico Central
    (5,  3, 'Tio JoÃ£o'),       -- Arroz Branco         / Distrib. GrÃ£os Brasil
    (6,  3, 'Camil'),          -- FeijÃ£o Carioca       / Distrib. GrÃ£os Brasil
    (7,  4, 'Cisne'),          -- Sal Refinado         / Temperos & Cia
    (8,  4, 'Liza'),           -- Ã“leo de Soja         / Temperos & Cia
    (9,  5, 'Coca-Cola'),      -- Refrigerante 2L      / Distrib. de Bebidas
    (10, 5, 'Crystal');        -- Ãgua Mineral 500ml   / Distrib. de Bebidas
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
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Joao Pedro Lima' WHEN 1 THEN 'JoÃ£o Silva Santos' WHEN 2 THEN 'JoÃ£o Oliveira' WHEN 3 THEN 'JoÃ£o da Costa' ELSE 'JoÃ£o Ferreira' END, 
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

