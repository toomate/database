SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
drop database if exists toomate;
create database if not exists toomate;
USE toomate;

drop user if exists 'toomate_user'@'%';
create user 'toomate_user'@'%' identified by 'toomate_password';
grant all on toomate.* to 'toomate_user'@'%';

flush privileges;

/*
*/
CREATE TABLE Usuario (
    idUsuario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    apelido VARCHAR(45),
    senha CHAR(64),
    administrador TINYINT
);

CREATE TABLE categoria (
    idCategoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45)
);

CREATE TABLE insumo (
    idInsumo INT PRIMARY KEY AUTO_INCREMENT,
    fkCategoria INT,
    nome VARCHAR(45),
    qtdMinima INT,
    rotatividade TINYINT,
    ativo TINYINT,
    CONSTRAINT fk_insumo_categoria FOREIGN KEY (fkCategoria) REFERENCES categoria(idCategoria)
);

CREATE TABLE rotina (
    idRotina INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(45)
);

CREATE TABLE rotinaInsumo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    idRotina INT,
    idInsumo INT,
    quantidadeInsumo INT,
    unidadeMedida VARCHAR(45),
    CONSTRAINT fk_rotinaInsumo_rotina FOREIGN KEY (idRotina) REFERENCES rotina(idRotina),
    CONSTRAINT fk_rotinaInsumo_insumo FOREIGN KEY (idInsumo) REFERENCES insumo(idInsumo)
);

CREATE TABLE fornecedor (
    idFornecedor INT PRIMARY KEY AUTO_INCREMENT,
    linkWhatsapp VARCHAR(100),
    razaoSocial VARCHAR(45),
    telefone VARCHAR(45)
);

CREATE TABLE marca (
    idMarca INT PRIMARY KEY AUTO_INCREMENT,
    fkInsumo INT,
    fkFornecedor INT,
    nomeMarca VARCHAR(45),
    CONSTRAINT fk_marca_insumo FOREIGN KEY (fkInsumo) REFERENCES insumo(idInsumo),
    CONSTRAINT fk_marca_fornecedor FOREIGN KEY (fkFornecedor) REFERENCES fornecedor(idFornecedor)
);

CREATE TABLE lote (
    idLote INT PRIMARY KEY AUTO_INCREMENT,
    dataValidade DATE,
    precoUnit DECIMAL(5,2),
    unidadeMedida VARCHAR(20),
    quantidadeMedida DOUBLE,
    quantidadeOriginal INT,
    quantidadeAtual INT,
    dataEntrada DATETIME,
    ativo TINYINT,
    fkMarca INT,
    fkUsuario INT,
    CONSTRAINT fk_lote_marca FOREIGN KEY (fkMarca) REFERENCES marca(idMarca),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (fkUsuario) REFERENCES Usuario(idUsuario)
);


CREATE TABLE historicoLote (
    idHistorico INT PRIMARY KEY AUTO_INCREMENT,
    fkLote INT,
    quantidadeRetirada INT,
    dataHoraAlteracao DATETIME,
    CONSTRAINT fk_historicoLote_lote FOREIGN KEY (fkLote) REFERENCES lote(idLote)
);


CREATE TABLE arquivo (
    idArquivo INT PRIMARY KEY AUTO_INCREMENT,
    nomeOriginal VARCHAR(45),
    chave VARCHAR(45),
    nomeBucket VARCHAR(45),
    dtCriacao DATETIME,
    dtAlteracao DATETIME
);

CREATE TABLE arquivoRelacionamento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fkArquivo INT,
    tipoEntidade VARCHAR(45),
    idEntidade INT,
	CONSTRAINT fk_arq_rel_arquivo FOREIGN KEY (fkArquivo) REFERENCES arquivo(idArquivo)
);

CREATE TABLE cliente (
    idCliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    telefone VARCHAR(45),
    cep VARCHAR(45),
    logradouro VARCHAR(45),
    bairro VARCHAR(45)
);

CREATE TABLE divida (
    idDivida INT PRIMARY KEY AUTO_INCREMENT,
    valor DECIMAL(10,2),
    dataCompra DATETIME,
    dataPagamento DATETIME,
    pedido VARCHAR(200),
    pago TINYINT,
    fkCliente INT,
    CONSTRAINT fk_divida_cliente FOREIGN KEY (fkCliente) REFERENCES cliente(idCliente)
);

CREATE TABLE boleto (
    idBoleto INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(45),
    categoria VARCHAR(20),
    pago TINYINT,
    dataVencimento DATETIME,
    dataPagamento DATETIME,
    valor DECIMAL(10,2),
    fkFornecedor INT,
    CONSTRAINT fk_boleto_fornecedor FOREIGN KEY (fkFornecedor) REFERENCES fornecedor(idFornecedor)
);


-- VIEWS
-- 1. KPI: Itens vencendo em 7 dias ou menos (incluindo vencidos)
CREATE VIEW vw_kpi_validade_proxima AS
SELECT 
    i.nome AS Insumo, 
    l.dataValidade, 
    l.quantidadeAtual AS QtdAtual,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasParaVencer
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
AND i.ativo = 1;


-- 2. KPI: Itens com estoque abaixo ou igual ao minimo
CREATE VIEW vw_kpi_estoque_baixo AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeAtual) AS EstoqueTotal,
    i.qtdMinima
FROM insumo i
LEFT JOIN marca m ON i.idInsumo = m.fkInsumo
LEFT JOIN lote l ON m.idMarca = l.fkMarca
WHERE i.ativo = 1
GROUP BY i.idInsumo, i.nome, i.qtdMinima
HAVING EstoqueTotal <= i.qtdMinima OR EstoqueTotal IS NULL;


-- 3. KPI: Contas (Boletos) ja vencidas
CREATE VIEW vw_kpi_contas_atrasadas AS
SELECT count(*) as QtdAtrasadas
FROM boleto
WHERE pago = 0 AND dataVencimento < CURDATE();


-- 4. Grafico: Estoque Atual vs Minimo (Para visualizaçao)
CREATE VIEW vw_grafico_estoque_vs_minimo AS
SELECT 
    i.nome AS Insumo,
    COALESCE(SUM(l.quantidadeAtual), 0) AS EstoqueAtual,
    i.qtdMinima AS EstoqueMinimo,
    CASE 
        WHEN COALESCE(SUM(l.quantidadeAtual), 0) < i.qtdMinima THEN 'Repor Urgente'
        ELSE 'OK' 
    END AS Status
FROM insumo i
LEFT JOIN marca m ON i.idInsumo = m.fkInsumo
LEFT JOIN lote l ON m.idMarca = l.fkMarca
WHERE i.ativo = 1
GROUP BY i.idInsumo, i.nome, i.qtdMinima;


-- 5. KPI: Boletos vencendo nos proximos 7 dias
CREATE VIEW vw_kpi_boletos_vencimento_proximo AS
SELECT * FROM boleto
WHERE pago = 0 
  AND dataVencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);


-- 6. Soma: Valor total de contas que vencem nesta semana
CREATE VIEW vw_total_contas_semana AS
SELECT COALESCE(SUM(valor), 0) AS ValorTotalSemana
FROM boleto
WHERE YEARWEEK(dataVencimento, 1) = YEARWEEK(CURDATE(), 1);


-- 7. AnAlise: Boleto "Em aberto" de maior valor
CREATE VIEW vw_boleto_maior_valor_aberto AS
SELECT * FROM boleto
WHERE pago = 0
ORDER BY valor DESC
LIMIT 1;


-- 8. KPI: Boletos que vencem no mês atual (Independente de pago ou nao)
CREATE VIEW vw_kpi_boletos_mes_atual AS
SELECT count(*) AS QtdBoletosMes
FROM boleto
WHERE MONTH(dataVencimento) = MONTH(CURDATE()) 
  AND YEAR(dataVencimento) = YEAR(CURDATE());


-- 9. Soma: Valor total de contas "Em atraso"
CREATE VIEW vw_total_valor_atrasado AS
SELECT COALESCE(SUM(valor), 0) AS TotalDividaFornecedor
FROM boleto
WHERE pago = 0 AND dataVencimento < CURDATE();


-- 10. Soma: Valor total que clientes devem ao estabelecimento
CREATE VIEW vw_total_divida_clientes AS
SELECT COALESCE(SUM(valor), 0) AS TotalReceber
FROM divida
WHERE pago = 0;


-- 11. AnAlise: Cliente com a maior divida acumulada
CREATE VIEW vw_cliente_maior_devedor AS
SELECT 
    c.nome, 
    c.telefone, 
    SUM(d.valor) AS TotalDevido
FROM cliente c
JOIN divida d ON c.idCliente = d.fkCliente
WHERE d.pago = 0
GROUP BY c.idCliente, c.nome, c.telefone
ORDER BY TotalDevido DESC
LIMIT 1;


-- 12. AnAlise: Pedido em aberto mais antigo
CREATE VIEW vw_pedido_aberto_mais_antigo AS
SELECT 
    c.nome AS Cliente,
    d.dataCompra,
    d.valor,
    d.pedido,
    DATEDIFF(CURDATE(), d.dataCompra) AS DiasEmAberto
FROM divida d
JOIN cliente c ON d.fkCliente = c.idCliente
WHERE d.pago = 0
ORDER BY d.dataCompra ASC
LIMIT 1;


-- 13. Prediçao: Item que provavelmente faltarA (Estoque < 10% acima do minimo)
-- LOgica: Ordena pelos itens que estao mais prOximos da margem de segurança
CREATE VIEW vw_predicao_falta_estoque AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeAtual) AS EstoqueAtual,
    i.qtdMinima,
    (SUM(l.quantidadeAtual) - i.qtdMinima) AS MargemSeguranca
FROM insumo i
JOIN marca m ON i.idInsumo = m.fkInsumo
JOIN lote l ON m.idMarca = l.fkMarca
GROUP BY i.idInsumo, i.nome, i.qtdMinima
HAVING EstoqueAtual > 0 
ORDER BY MargemSeguranca ASC
LIMIT 1;

-- 14. Prediçao: Item que provavelmente vencerA antes de ser usado
-- LOgica: Itens com muita quantidade em estoque mas validade muito curta (ex: vence em 3 dias)
CREATE VIEW vw_predicao_perda_validade AS
SELECT 
    i.nome AS Insumo,
    l.quantidadeAtual AS QtdNoLote,
    l.dataValidade,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasRestantes
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade > CURDATE() -- Ainda nao venceu
  AND DATEDIFF(l.dataValidade, CURDATE()) <= 5 -- Vence em 5 dias ou menos
ORDER BY l.quantidadeAtual DESC -- Prioriza os que tem maior quantidade em risco
LIMIT 1;


-- 15. Financeiro Estoque: Valor total de itens cadastrados na semana atual
CREATE VIEW vw_total_entrada_estoque_semana AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeAtual), 0) AS ValorTotalEntradas
FROM lote l
WHERE YEARWEEK(l.dataEntrada, 1) = YEARWEEK(CURDATE(), 1);


-- 16. Perda: Valor total de itens perdidos (Vencidos e ainda em estoque)
CREATE VIEW vw_total_perda_validade AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeAtual), 0) AS ValorTotalPerda
FROM lote l
WHERE l.dataValidade < CURDATE()
AND l.quantidadeAtual > 0; -- Considera perda apenas se ainda tiver itens em estoque




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
    ('Proteinas'),               -- ID 1
    ('Pescados'),                -- ID 2
    ('Hortifruti'),              -- ID 3
    ('Laticinios'),              -- ID 4
    ('Frios e Embutidos'),       -- ID 5
    ('Graos e Secos'),           -- ID 6
    ('Temperos e Condimentos'),  -- ID 7
    ('Oleos e Gorduras'),        -- ID 8
    ('Bebidas');                 -- ID 9

INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('Laticinios do Vale Ltda',         '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Frigorifico Central S.A.',        '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora Graos Brasil Ltda', '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Temperos & Cia Ltda',             '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora de Bebidas S.A.',   '(11) 5897-2493', 'https://wa.me/551158972493');

INSERT INTO insumo (fkCategoria, nome, qtdMinima, rotatividade, ativo) VALUES
    (1, 'Peito de Frango',        6, 1, 1),  
    (1, 'Carne Bovina Moida',     5, 1, 1),  
    (1, 'Carne Suina',            4, 1, 1),  
    (2, 'File de Tilapia',        4, 1, 1),  
    (2, 'Sardinha',               6, 0, 1),  
    (3, 'Cebola',                 8, 1, 1),  
    (3, 'Alho',                   3, 1, 1),  
    (3, 'Tomate',                 8, 1, 1),  
    (4, 'Leite Integral',        12, 1, 1),  
    (4, 'Queijo Mussarela',       4, 1, 1),  
    (4, 'Manteiga',               3, 1, 1),  
    (5, 'Bacon',                  3, 1, 1),  
    (5, 'Linguica Toscana',       4, 1, 1),  
    (5, 'Presunto',               3, 1, 1),  
    (6, 'Arroz Branco',          10, 0, 1),  
    (6, 'Feijao Carioca',         8, 0, 1),  
    (6, 'Farinha de Trigo',       6, 0, 1),  
    (6, 'Macarrao Espaguete',     8, 0, 1),  
    (7, 'Sal Refinado',           3, 0, 1),  
    (7, 'Pimenta do Reino',       2, 0, 1),  
    (7, 'Molho de Tomate',       10, 1, 1),  
    (7, 'Vinagre',                2, 0, 1),  
    (8, 'Oleo de Soja',           4, 0, 1),  
    (8, 'Azeite',                 2, 0, 1),  
    (9, 'Refrigerante',          18, 0, 1),  
    (9, 'Agua Mineral',          36, 0, 1),  
    (9, 'Suco de Laranja',       12, 1, 1);

INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    (1,  2, 'Sadia'),
    (1,  2, 'Seara'),
    (2,  2, 'Friboi'),
    (2,  2, 'Swift'),
    (3,  2, 'Aurora'),
    (3,  2, 'Perdigao'),
    (4,  2, 'Copacol'),
    (4,  2, 'Qualita'),
    (5,  2, 'Coqueiro'),
    (5,  2, 'Gomes da Costa'),
    (6,  3, 'Hortifruti Central'),
    (6,  3, 'Sitio do Joao'),
    (7,  3, 'Hortifruti Central'),
    (7,  3, 'Sitio do Joao'),
    (8,  3, 'Hortifruti Central'),
    (8,  3, 'Sitio do Joao'),
    (9,  1, 'Italac'),
    (9,  1, 'Piracanjuba'),
    (10, 1, 'Polenghi'),
    (10, 1, 'Tirolez'),
    (11, 1, 'Aviacao'),
    (11, 1, 'Vigor'),
    (12, 2, 'Seara'),
    (12, 2, 'Perdigao'),
    (13, 2, 'Aurora'),
    (13, 2, 'Seara'),
    (14, 1, 'Sadia'),
    (14, 1, 'Perdigao'),
    (15, 3, 'Camil'),
    (15, 3, 'Tio Joao'),
    (16, 3, 'Camil'),
    (16, 3, 'Kicaldo'),
    (17, 3, 'Dona Benta'),
    (17, 3, 'Sol'),
    (18, 3, 'Renata'),
    (18, 3, 'Adria'),
    (19, 4, 'Cisne'),
    (19, 4, 'Qualita'),
    (20, 4, 'Kitano'),
    (20, 4, 'Bombay'),
    (21, 4, 'Pomarola'),
    (21, 4, 'Elefante'),
    (22, 4, 'Castelo'),
    (22, 4, 'Qualita'),
    (23, 4, 'Liza'),
    (23, 4, 'Soya'),
    (24, 4, 'Gallo'),
    (24, 4, 'Andorinha'),
    (25, 5, 'Coca-Cola'),
    (25, 5, 'Antarctica'),
    (26, 5, 'Crystal'),
    (26, 5, 'Minalba'),
    (27, 5, 'Del Valle'),
    (27, 5, 'Maguary'); 

INSERT INTO lote (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada, ativo) VALUES
    (1,  1, DATE_ADD(CURDATE(), INTERVAL  5 DAY),  15.90, 'kg', 1,  12, 10, NOW(), 1), -- Peito de Frango (Sadia)
    (3,  2, DATE_ADD(CURDATE(), INTERVAL  6 DAY),  32.90, 'kg', 1,  10,  7, NOW(), 1), -- Carne Moida (Friboi)
    (5,  1, DATE_ADD(CURDATE(), INTERVAL  7 DAY),  28.90, 'kg', 1,   8,  6, NOW(), 1), -- Carne Suina (Aurora)
    (7,  3, DATE_ADD(CURDATE(), INTERVAL  4 DAY),  34.90, 'kg', 1,   6,  5, NOW(), 1), -- TilApia (Copacol)
    (9,  3, DATE_ADD(CURDATE(), INTERVAL 10 DAY),  10.90, 'un', 1,  24, 18, NOW(), 1), -- Sardinha (Coqueiro)
    (11, 2, DATE_ADD(CURDATE(), INTERVAL 12 DAY),   6.50, 'kg', 1,  10,  8, NOW(), 1), -- Cebola
    (13, 2, DATE_ADD(CURDATE(), INTERVAL 20 DAY),  22.00, 'kg', 1,   3,  2, NOW(), 1), -- Alho
    (15, 2, DATE_ADD(CURDATE(), INTERVAL  7 DAY),   8.90, 'kg', 1,   8,  6, NOW(), 1), -- Tomate
    (17, 1, DATE_ADD(CURDATE(), INTERVAL  8 DAY),   5.49, 'L',  1,  18, 14, NOW(), 1), -- Leite (Italac)
    (19, 1, DATE_ADD(CURDATE(), INTERVAL 12 DAY),  39.90, 'kg', 1,   6,  4, NOW(), 1), -- Mussarela (Polenghi)
    (21, 1, DATE_ADD(CURDATE(), INTERVAL 25 DAY), 17.90, 'g', 200, 12, 9, NOW(), 1), -- Manteiga (Aviacao) - tablete 200g
    (23, 1, DATE_ADD(CURDATE(), INTERVAL 15 DAY),  29.90, 'kg', 1,   5,  4, NOW(), 1), -- Bacon
    (25, 2, DATE_ADD(CURDATE(), INTERVAL 12 DAY),  19.90, 'kg', 1,   6,  5, NOW(), 1), -- Linguiça
    (27, 2, DATE_ADD(CURDATE(), INTERVAL 10 DAY),  18.50, 'kg', 1,   4,  3, NOW(), 1), -- Presunto
    (29, 3, DATE_ADD(CURDATE(), INTERVAL 10 MONTH), 27.90, 'kg', 5,   4,  4, NOW(), 1), -- Arroz (pacote 5kg) qtd=4 pacotes
    (31, 3, DATE_ADD(CURDATE(), INTERVAL  9 MONTH),  8.90, 'kg', 1,   8,  7, NOW(), 1), -- Feijao
    (33, 3, DATE_ADD(CURDATE(), INTERVAL  8 MONTH),  6.90, 'kg', 1,   6,  5, NOW(), 1), -- Farinha trigo
    (35, 3, DATE_ADD(CURDATE(), INTERVAL  9 MONTH),  4.90, 'un', 500, 10,  9, NOW(), 1), -- Macarrao (pacote 500g)
    (37, 2, DATE_ADD(CURDATE(), INTERVAL 18 MONTH),  3.20, 'kg', 1,   2,  2, NOW(), 1), -- Sal
    (39, 2, DATE_ADD(CURDATE(), INTERVAL 24 MONTH),  6.50, 'g',  50,  6,  5, NOW(), 1), -- Pimenta (pote 50g)
    (43, 2, DATE_ADD(CURDATE(), INTERVAL 18 MONTH),  4.90, 'ml', 750,  4,  3, NOW(), 1), -- Vinagre (750ml)
    (45, 1, DATE_ADD(CURDATE(), INTERVAL 14 MONTH),  7.90, 'ml', 900,  6,  5, NOW(), 1), -- Oleo (900ml
    (49, 3, DATE_ADD(CURDATE(), INTERVAL  4 MONTH),  8.90, 'L',    2, 24, 20, NOW(), 1), -- Refrigerante (2L)
    (53, 3, DATE_ADD(CURDATE(), INTERVAL  3 MONTH),  7.90, 'L',    1, 18, 15, NOW(), 1); -- Suco (1L)

INSERT INTO lote (fkMarca, fkUsuario, dataValidade, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada, ativo) VALUES
    (2,  2, DATE_ADD(CURDATE(), INTERVAL  2 DAY),  15.50, 'kg', 1,  8, 6, DATE_SUB(NOW(), INTERVAL 2 DAY), 1),
    (4,  3, DATE_ADD(CURDATE(), INTERVAL  3 DAY),  33.90, 'kg', 1,  6, 4, DATE_SUB(NOW(), INTERVAL 1 DAY), 1),
    (8,  1, DATE_ADD(CURDATE(), INTERVAL  2 DAY),  33.50, 'kg', 1,  4, 3, DATE_SUB(NOW(), INTERVAL 1 DAY), 1),
    (18, 1, DATE_ADD(CURDATE(), INTERVAL  5 DAY),   5.29, 'L',  1, 12, 9, DATE_SUB(NOW(), INTERVAL 3 DAY), 1),
    (20, 2, DATE_ADD(CURDATE(), INTERVAL  9 DAY),  41.90, 'kg', 1,  4, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), 1),
    (42, 3, DATE_ADD(CURDATE(), INTERVAL  5 MONTH), 3.10, 'g', 340, 12, 9, DATE_SUB(NOW(), INTERVAL 10 DAY), 1),
    (50, 3, DATE_ADD(CURDATE(), INTERVAL  3 MONTH), 7.90, 'L',   2, 12, 8, DATE_SUB(NOW(), INTERVAL 5 DAY), 1),
    (52, 2, DATE_ADD(CURDATE(), INTERVAL 11 MONTH), 1.10, 'ml', 500, 24, 18, DATE_SUB(NOW(), INTERVAL 15 DAY), 1);

-- BLOCO DE LOTES 3: Terceiro lote para produtos de altissima saida em restaurantes
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, unidadeMedida, quantidadeMedida, quantidadeOriginal, quantidadeAtual, dataEntrada, dataValidade, ativo) VALUES
    -- Arroz (ex: pacotes de 5kg) - alta saida, mas em volumes plausiveis
    (5,  1, ROUND(25.30 + RAND() * 3.00, 2), 'kg', 5,   FLOOR(8  + RAND() * 8),  FLOOR(4  + RAND() * 6),  NOW(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH), 1),

    -- Feijao (1kg)
    (6,  2, ROUND(6.40  + RAND() * 1.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 10), FLOOR(6  + RAND() * 8),  NOW(), DATE_ADD(CURDATE(), INTERVAL 11 MONTH), 1),

    -- Refrigerante (2L)
    (9,  3, ROUND(8.60  + RAND() * 1.50, 2), 'L',  2,   FLOOR(12 + RAND() * 12), FLOOR(6  + RAND() * 10), NOW(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH), 1),

    -- Peito de Frango (1kg)
    (16, 1, ROUND(12.20 + RAND() * 2.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 10), FLOOR(5  + RAND() * 8),  NOW(), DATE_ADD(CURDATE(), INTERVAL 6 DAY), 1),

    -- Macarrao (pacote 500g)
    (24, 2, ROUND(3.30  + RAND() * 1.00, 2), 'g',  500, FLOOR(12 + RAND() * 12), FLOOR(6  + RAND() * 10), NOW(), DATE_ADD(CURDATE(), INTERVAL 15 MONTH), 1),

    -- Cebola (ex: saco de 20kg) - restaurante pequeno nao teria 80 sacos; coloquei baixo
    (39, 3, ROUND(82.90 + RAND() * 5.00, 2), 'kg', 20,  FLOOR(2  + RAND() * 3),  FLOOR(1  + RAND() * 2),  NOW(), DATE_ADD(CURDATE(), INTERVAL 25 DAY), 1);


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
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Joao Pedro Lima' WHEN 1 THEN 'Anselmo Silva Santos' WHEN 2 THEN 'Joao Oliveira' WHEN 3 THEN 'Carlos da Costa' ELSE 'Felipe Ferreira' END, 
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

    -- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: toomate
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `arquivo`
--

DROP TABLE IF EXISTS `arquivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `arquivo` (
  `idArquivo` int NOT NULL AUTO_INCREMENT,
  `nomeOriginal` varchar(255) DEFAULT NULL,
  `chave` varchar(255) DEFAULT NULL,
  `nomeBucket` varchar(255) DEFAULT NULL,
  `dtCriacao` date DEFAULT NULL,
  `dtAlteracao` date DEFAULT NULL,
  PRIMARY KEY (`idArquivo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `arquivo`
--

LOCK TABLES `arquivo` WRITE;
/*!40000 ALTER TABLE `arquivo` DISABLE KEYS */;
/*!40000 ALTER TABLE `arquivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `arquivorelacionamento`
--

DROP TABLE IF EXISTS `arquivorelacionamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `arquivorelacionamento` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fkArquivo` int DEFAULT NULL,
  `tipoEntidade` varchar(255) DEFAULT NULL,
  `idEntidade` int DEFAULT NULL,
  `categoria` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_arq_rel_arquivo` (`fkArquivo`),
  CONSTRAINT `fk_arq_rel_arquivo` FOREIGN KEY (`fkArquivo`) REFERENCES `arquivo` (`idArquivo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `arquivorelacionamento`
--

LOCK TABLES `arquivorelacionamento` WRITE;
/*!40000 ALTER TABLE `arquivorelacionamento` DISABLE KEYS */;
/*!40000 ALTER TABLE `arquivorelacionamento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `boleto`
--

DROP TABLE IF EXISTS `boleto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `boleto` (
  `idBoleto` int NOT NULL AUTO_INCREMENT,
  `descricao` varchar(255) DEFAULT NULL,
  `categoria` varchar(255) DEFAULT NULL,
  `pago` bit(1) DEFAULT NULL,
  `dataVencimento` date DEFAULT NULL,
  `dataPagamento` date DEFAULT NULL,
  `valor` double DEFAULT NULL,
  `fkFornecedor` int DEFAULT NULL,
  PRIMARY KEY (`idBoleto`),
  KEY `fk_boleto_fornecedor` (`fkFornecedor`),
  CONSTRAINT `fk_boleto_fornecedor` FOREIGN KEY (`fkFornecedor`) REFERENCES `fornecedor` (`idFornecedor`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `boleto`
--

LOCK TABLES `boleto` WRITE;
/*!40000 ALTER TABLE `boleto` DISABLE KEYS */;
INSERT INTO `boleto` VALUES (1,'Boleto energia - Janeiro','Contas Consumo',_binary '','2026-01-10','2026-01-08',546.43,3),(2,'Boleto fornecedor - Janeiro','Boletos Fornecedores',_binary '\0','2026-01-20','1970-01-01',803.65,1),(3,'Boleto energia - Fevereiro','Contas Consumo',_binary '','2026-02-10','2026-02-09',560.34,3),(4,'Boleto fornecedor - Fevereiro','Boletos Fornecedores',_binary '\0','2026-02-18','1970-01-01',853.55,5),(5,'Boleto energia - Marco','Contas Consumo',_binary '','2026-03-10','2026-03-08',555.63,1),(6,'Boleto fornecedor - Marco','Boletos Fornecedores',_binary '\0','2026-03-20','1970-01-01',942.18,4),(7,'Boleto energia - Abril','Contas Consumo',_binary '','2026-04-10','2026-04-09',501.47,3),(8,'Boleto fornecedor - Abril','Boletos Fornecedores',_binary '\0','2026-04-20','1970-01-01',787.86,1),(9,'Boleto energia - Maio','Contas Consumo',_binary '','2026-05-10','2026-05-07',507.51,4),(10,'Boleto fornecedor - Maio','Boletos Fornecedores',_binary '\0','2026-05-21','1970-01-01',837.96,5),(11,'Boleto energia - Junho','Contas Consumo',_binary '','2026-06-10','2026-06-05',563.14,1),(12,'Boleto fornecedor - Junho','Boletos Fornecedores',_binary '\0','2026-06-20','1970-01-01',801.17,5),(13,'Boleto energia - Julho','Contas Consumo',_binary '','2026-07-10','2026-07-08',461.14,1),(14,'Boleto fornecedor - Julho','Boletos Fornecedores',_binary '\0','2026-07-21','1970-01-01',876.46,3),(15,'Boleto energia - Agosto','Contas Consumo',_binary '','2026-08-10','2026-08-09',602.3,4),(16,'Boleto fornecedor - Agosto','Boletos Fornecedores',_binary '\0','2026-08-20','1970-01-01',964.4,3),(17,'Boleto energia - Setembro','Contas Consumo',_binary '','2026-09-10','2026-09-06',499.7,2),(18,'Boleto fornecedor - Setembro','Boletos Fornecedores',_binary '\0','2026-09-20','1970-01-01',868.71,1),(19,'Boleto energia - Outubro','Contas Consumo',_binary '','2026-10-10','2026-10-07',554.37,4),(20,'Boleto fornecedor - Outubro','Boletos Fornecedores',_binary '\0','2026-10-20','1970-01-01',853.55,1),(21,'Boleto energia - Novembro','Contas Consumo',_binary '','2026-11-10','2026-11-08',508.42,5),(22,'Boleto fornecedor - Novembro','Boletos Fornecedores',_binary '\0','2026-11-20','1970-01-01',883.23,1),(23,'Boleto energia - Dezembro','Contas Consumo',_binary '','2026-12-10','2026-12-07',581.85,2),(24,'Boleto fornecedor - Dezembro','Boletos Fornecedores',_binary '\0','2026-12-20','1970-01-01',882.16,1);
/*!40000 ALTER TABLE `boleto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categoria`
--

DROP TABLE IF EXISTS `categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria` (
  `idCategoria` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idCategoria`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria`
--

LOCK TABLES `categoria` WRITE;
/*!40000 ALTER TABLE `categoria` DISABLE KEYS */;
INSERT INTO `categoria` VALUES (1,'Proteinas'),(2,'Pescados'),(3,'Hortifruti'),(4,'Laticinios'),(5,'Frios e Embutidos'),(6,'Graos e Secos'),(7,'Temperos e Condimentos'),(8,'Oleos e Gorduras'),(9,'Bebidas');
/*!40000 ALTER TABLE `categoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cliente`
--

DROP TABLE IF EXISTS `cliente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cliente` (
  `idCliente` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) DEFAULT NULL,
  `telefone` varchar(255) DEFAULT NULL,
  `cep` varchar(255) DEFAULT NULL,
  `logradouro` varchar(255) DEFAULT NULL,
  `bairro` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idCliente`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cliente`
--

LOCK TABLES `cliente` WRITE;
/*!40000 ALTER TABLE `cliente` DISABLE KEYS */;
INSERT INTO `cliente` VALUES (1,'Felipe Ferreira','(11) 99826-8847','68409-765','Rua das Palmeiras, 120','Centro'),(2,'Beatriz Santos','(11) 99192-6442','43252-229','Av. Paulista, 1500','Bela Vista'),(3,'Rafael Santos','(11) 99138-2915','74976-873','Rua do Carmo, 45','Mooca'),(4,'Patricia Nunes Rocha','(11) 99965-5503','80371-367','Rua Voluntarios, 300','Santana'),(5,'Rodrigo Costa','(11) 98063-8772','29141-824','Rua Clovis, 88','Lapa');
/*!40000 ALTER TABLE `cliente` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `divida`
--

DROP TABLE IF EXISTS `divida`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `divida` (
  `idDivida` int NOT NULL AUTO_INCREMENT,
  `valor` double DEFAULT NULL,
  `dataCompra` date DEFAULT NULL,
  `dataPagamento` date DEFAULT NULL,
  `pedido` varchar(255) DEFAULT NULL,
  `pago` bit(1) DEFAULT NULL,
  `fkCliente` int DEFAULT NULL,
  PRIMARY KEY (`idDivida`),
  KEY `fk_divida_cliente` (`fkCliente`),
  CONSTRAINT `fk_divida_cliente` FOREIGN KEY (`fkCliente`) REFERENCES `cliente` (`idCliente`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `divida`
--

LOCK TABLES `divida` WRITE;
/*!40000 ALTER TABLE `divida` DISABLE KEYS */;
INSERT INTO `divida` VALUES (1,75.28,'2026-05-07','2026-06-01','PF-5420',_binary '',1),(2,33.36,'2026-06-04','1970-01-01','PF-5426',_binary '\0',1),(3,90.46,'2026-05-12','2026-05-27','PF-4638',_binary '',2),(4,108.95,'2026-06-03','2026-06-05','PF-1423',_binary '',2),(5,167.35,'2026-03-22','1970-01-01','PF-7425',_binary '\0',3),(6,44.45,'2026-06-08','1970-01-01','PF-5667',_binary '\0',3),(7,122.69,'2026-05-27','2026-06-03','PF-1469',_binary '',4),(8,173.83,'2026-05-24','1970-01-01','PF-8306',_binary '\0',4),(9,219.61,'2026-02-10','1970-01-01','PF-4910',_binary '\0',5),(10,86.45,'2026-05-19','2026-05-30','PF-7222',_binary '',5);
/*!40000 ALTER TABLE `divida` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fornecedor`
--

DROP TABLE IF EXISTS `fornecedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fornecedor` (
  `idFornecedor` int NOT NULL AUTO_INCREMENT,
  `linkWhatsapp` varchar(255) DEFAULT NULL,
  `razaoSocial` varchar(255) DEFAULT NULL,
  `telefone` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idFornecedor`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fornecedor`
--

LOCK TABLES `fornecedor` WRITE;
/*!40000 ALTER TABLE `fornecedor` DISABLE KEYS */;
INSERT INTO `fornecedor` VALUES (1,'https://wa.me/551158972493','Laticinios do Vale Ltda','(11) 5897-2493'),(2,'https://wa.me/551158972493','Frigorifico Central S.A.','(11) 5897-2493'),(3,'https://wa.me/551158972493','Distribuidora Graos Brasil Ltda','(11) 5897-2493'),(4,'https://wa.me/551158972493','Temperos & Cia Ltda','(11) 5897-2493'),(5,'https://wa.me/551158972493','Distribuidora de Bebidas S.A.','(11) 5897-2493');
/*!40000 ALTER TABLE `fornecedor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historicolote`
--

DROP TABLE IF EXISTS `historicolote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historicolote` (
  `idHistorico` int NOT NULL AUTO_INCREMENT,
  `fkLote` int DEFAULT NULL,
  `quantidadeRetirada` int DEFAULT NULL,
  `dataHoraAlteracao` datetime DEFAULT NULL,
  PRIMARY KEY (`idHistorico`),
  KEY `fk_historicoLote_lote` (`fkLote`),
  CONSTRAINT `fk_historicoLote_lote` FOREIGN KEY (`fkLote`) REFERENCES `lote` (`idLote`)
) ENGINE=InnoDB AUTO_INCREMENT=3148 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historicolote`
--

LOCK TABLES `historicolote` WRITE;
/*!40000 ALTER TABLE `historicolote` DISABLE KEYS */;
INSERT INTO `historicolote` VALUES (2,34,3,'2026-01-01 18:01:25'),(3,7,2,'2026-01-01 11:33:11'),(6,95,1,'2026-01-01 12:21:39'),(7,2,2,'2026-01-01 10:37:32'),(8,99,1,'2026-01-01 15:13:39'),(9,5,2,'2026-01-01 11:46:05'),(10,32,2,'2026-01-01 17:18:42'),(11,3,2,'2026-01-01 16:49:50'),(12,26,2,'2026-01-01 15:05:54'),(15,31,1,'2026-01-02 17:01:43'),(16,38,1,'2026-01-02 10:14:04'),(17,14,2,'2026-01-02 14:44:32'),(18,15,1,'2026-01-02 10:58:56'),(19,32,1,'2026-01-02 18:08:17'),(22,21,3,'2026-01-02 18:19:26'),(24,5,3,'2026-01-02 09:17:42'),(25,3,1,'2026-01-02 15:59:53'),(26,1,3,'2026-01-02 14:27:12'),(27,77,1,'2026-01-02 16:26:13'),(28,4,3,'2026-01-02 12:09:46'),(29,104,1,'2026-01-02 10:22:07'),(30,89,3,'2026-01-02 15:41:11'),(31,10,3,'2026-01-02 13:23:15'),(34,92,1,'2026-01-02 10:49:10'),(35,101,3,'2026-01-02 14:11:59'),(36,10,1,'2026-01-03 15:18:55'),(39,96,3,'2026-01-03 10:13:33'),(41,83,3,'2026-01-03 10:36:04'),(42,27,2,'2026-01-03 09:53:09'),(43,97,1,'2026-01-03 15:43:21'),(44,18,1,'2026-01-03 16:12:08'),(47,9,3,'2026-01-03 16:21:40'),(48,15,3,'2026-01-03 18:56:12'),(49,102,3,'2026-01-04 15:44:05'),(51,95,2,'2026-01-04 16:27:51'),(52,76,3,'2026-01-04 17:44:38'),(53,20,3,'2026-01-04 16:02:20'),(54,20,2,'2026-01-04 17:04:52'),(55,94,1,'2026-01-04 16:32:53'),(58,79,3,'2026-01-04 14:38:22'),(59,4,2,'2026-01-04 18:53:30'),(60,9,3,'2026-01-04 09:52:20'),(62,102,1,'2026-01-04 11:45:44'),(65,16,1,'2026-01-04 09:58:02'),(66,36,2,'2026-01-04 12:46:18'),(68,26,1,'2026-01-04 12:44:26'),(69,3,2,'2026-01-04 18:49:05'),(71,100,1,'2026-01-04 15:26:51'),(73,37,2,'2026-01-04 09:38:41'),(75,98,1,'2026-01-05 15:45:48'),(77,106,1,'2026-01-05 13:29:40'),(82,103,1,'2026-01-05 12:39:57'),(83,2,2,'2026-01-05 15:21:04'),(84,22,3,'2026-01-05 18:14:09'),(85,105,1,'2026-01-05 18:27:15'),(86,82,1,'2026-01-05 10:03:03'),(87,25,2,'2026-01-05 10:42:32'),(88,22,2,'2026-01-05 17:37:14'),(89,26,1,'2026-01-05 10:41:02'),(90,5,1,'2026-01-05 14:20:13'),(91,12,1,'2026-01-05 11:02:14'),(93,106,1,'2026-01-05 09:30:47'),(94,13,3,'2026-01-05 15:43:10'),(96,12,1,'2026-01-06 13:32:54'),(99,25,3,'2026-01-06 16:28:19'),(100,3,1,'2026-01-06 09:49:53'),(101,24,3,'2026-01-06 15:03:16'),(102,86,1,'2026-01-06 16:29:25'),(103,101,1,'2026-01-06 15:32:10'),(104,75,2,'2026-01-06 15:06:12'),(106,12,2,'2026-01-06 14:24:28'),(107,75,1,'2026-01-06 14:09:46'),(109,17,2,'2026-01-06 10:09:22'),(110,9,1,'2026-01-06 12:30:49'),(113,17,3,'2026-01-06 17:38:59'),(114,13,2,'2026-01-06 14:12:09'),(117,32,3,'2026-01-06 12:28:52'),(118,103,3,'2026-01-06 17:13:41'),(119,5,2,'2026-01-06 16:32:43'),(121,82,1,'2026-01-06 14:23:54'),(122,35,3,'2026-01-07 09:19:55'),(124,77,3,'2026-01-07 18:51:06'),(126,75,2,'2026-01-07 15:47:00'),(128,32,3,'2026-01-07 16:41:11'),(129,81,3,'2026-01-07 17:19:44'),(131,27,1,'2026-01-07 09:09:26'),(132,2,2,'2026-01-07 12:14:51'),(133,34,2,'2026-01-07 15:39:10'),(134,77,2,'2026-01-07 13:50:13'),(135,23,3,'2026-01-07 09:01:22'),(136,103,2,'2026-01-07 10:56:11'),(138,34,2,'2026-01-07 16:31:05'),(139,9,3,'2026-01-07 13:34:45'),(142,78,3,'2026-01-07 09:50:43'),(143,19,2,'2026-01-07 13:34:28'),(144,84,1,'2026-01-08 16:02:42'),(147,11,2,'2026-01-08 18:54:57'),(149,80,1,'2026-01-08 18:37:16'),(150,14,1,'2026-01-08 15:31:59'),(152,101,3,'2026-01-08 12:43:11'),(156,25,1,'2026-01-09 11:23:04'),(158,37,2,'2026-01-09 14:50:56'),(159,6,2,'2026-01-09 14:46:32'),(160,84,1,'2026-01-09 11:25:26'),(161,104,2,'2026-01-09 17:25:38'),(162,105,2,'2026-01-09 11:05:09'),(163,24,1,'2026-01-09 13:53:12'),(164,36,2,'2026-01-09 13:58:23'),(165,91,3,'2026-01-09 16:50:08'),(166,75,2,'2026-01-09 09:33:34'),(167,32,1,'2026-01-09 14:31:51'),(168,105,2,'2026-01-09 17:23:02'),(169,37,3,'2026-01-09 16:38:05'),(170,105,1,'2026-01-09 12:06:47'),(171,103,1,'2026-01-09 15:57:37'),(172,93,1,'2026-01-09 12:39:37'),(174,31,2,'2026-01-09 16:42:07'),(177,80,2,'2026-01-10 18:28:52'),(179,32,3,'2026-01-10 16:03:25'),(181,112,2,'2026-01-10 12:06:45'),(182,105,2,'2026-01-10 10:41:52'),(183,36,1,'2026-01-10 18:18:11'),(186,31,3,'2026-01-10 15:53:22'),(187,106,2,'2026-01-10 09:36:13'),(188,1,2,'2026-01-10 10:54:32'),(189,114,2,'2026-01-10 15:26:21'),(191,114,3,'2026-01-10 17:02:04'),(192,82,2,'2026-01-10 16:41:07'),(194,28,1,'2026-01-10 15:07:34'),(195,33,2,'2026-01-10 15:01:08'),(196,103,1,'2026-01-11 11:59:16'),(197,5,2,'2026-01-11 15:29:51'),(198,104,2,'2026-01-11 10:45:18'),(199,16,3,'2026-01-11 15:38:48'),(201,87,1,'2026-01-11 13:42:09'),(202,5,1,'2026-01-11 14:02:28'),(203,106,1,'2026-01-11 17:10:28'),(206,18,3,'2026-01-11 17:03:10'),(207,105,2,'2026-01-11 16:52:11'),(208,31,2,'2026-01-11 18:51:10'),(210,8,1,'2026-01-11 10:53:06'),(211,123,2,'2026-01-11 11:53:22'),(212,6,3,'2026-01-11 13:57:19'),(213,33,2,'2026-01-12 15:47:58'),(214,112,2,'2026-01-12 14:33:06'),(215,18,3,'2026-01-12 09:45:31'),(217,29,1,'2026-01-12 17:09:22'),(219,79,1,'2026-01-12 16:56:15'),(220,104,1,'2026-01-12 15:37:21'),(222,101,1,'2026-01-12 09:00:05'),(223,29,1,'2026-01-12 17:20:46'),(224,81,1,'2026-01-12 14:15:37'),(225,24,2,'2026-01-12 11:04:24'),(226,81,2,'2026-01-12 15:37:17'),(227,18,1,'2026-01-12 12:11:17'),(228,16,1,'2026-01-12 11:40:22'),(229,23,1,'2026-01-13 15:12:43'),(231,9,3,'2026-01-13 18:18:45'),(232,115,1,'2026-01-13 16:06:39'),(233,30,2,'2026-01-13 10:26:33'),(234,124,2,'2026-01-13 15:29:30'),(235,82,2,'2026-01-13 17:28:19'),(238,11,1,'2026-01-13 15:58:48'),(239,78,1,'2026-01-13 10:42:50'),(241,18,1,'2026-01-14 18:00:01'),(243,1,3,'2026-01-14 14:56:56'),(244,78,2,'2026-01-14 10:56:32'),(247,35,3,'2026-01-14 12:22:15'),(249,97,1,'2026-01-14 18:58:35'),(250,105,2,'2026-01-14 09:38:30'),(251,88,1,'2026-01-14 16:07:50'),(252,6,1,'2026-01-14 10:53:53'),(253,126,1,'2026-01-15 12:10:41'),(254,124,1,'2026-01-15 10:44:59'),(256,1,2,'2026-01-15 12:13:52'),(257,102,1,'2026-01-15 16:01:26'),(258,89,2,'2026-01-15 12:26:52'),(260,102,1,'2026-01-15 09:01:21'),(261,130,1,'2026-01-15 17:16:18'),(263,104,1,'2026-01-15 15:30:22'),(265,126,1,'2026-01-15 13:54:21'),(266,123,3,'2026-01-15 09:09:29'),(267,103,1,'2026-01-15 16:01:38'),(268,102,2,'2026-01-15 16:29:34'),(269,123,2,'2026-01-15 13:26:23'),(270,83,1,'2026-01-15 11:17:07'),(272,105,2,'2026-01-15 10:03:20'),(273,37,3,'2026-01-15 16:31:38'),(275,114,1,'2026-01-15 12:32:25'),(277,37,3,'2026-01-16 12:28:15'),(278,6,2,'2026-01-16 13:21:03'),(279,36,1,'2026-01-16 09:44:07'),(281,11,1,'2026-01-16 09:33:21'),(282,102,3,'2026-01-16 11:55:10'),(283,32,1,'2026-01-16 17:01:43'),(284,32,2,'2026-01-16 13:04:30'),(286,32,2,'2026-01-16 12:56:43'),(287,33,1,'2026-01-16 11:00:06'),(288,114,1,'2026-01-17 17:38:43'),(289,16,2,'2026-01-17 09:02:42'),(290,129,1,'2026-01-17 10:31:54'),(291,35,2,'2026-01-17 10:10:08'),(292,11,3,'2026-01-17 11:30:47'),(295,115,1,'2026-01-17 18:09:56'),(298,103,1,'2026-01-17 12:25:57'),(299,11,2,'2026-01-17 17:30:32'),(300,29,1,'2026-01-17 10:15:37'),(301,28,2,'2026-01-17 16:00:53'),(302,104,1,'2026-01-18 09:28:13'),(303,8,1,'2026-01-18 16:15:44'),(304,126,1,'2026-01-18 18:09:25'),(307,106,3,'2026-01-18 11:28:31'),(309,89,1,'2026-01-18 17:56:25'),(310,2,1,'2026-01-18 13:58:25'),(311,35,1,'2026-01-18 17:09:47'),(312,104,2,'2026-01-18 15:56:09'),(313,105,3,'2026-01-18 10:29:20'),(314,80,1,'2026-01-18 10:26:30'),(315,36,2,'2026-01-18 13:08:21'),(316,105,1,'2026-01-18 13:57:22'),(318,28,2,'2026-01-18 14:14:11'),(319,24,1,'2026-01-18 10:36:11'),(320,24,1,'2026-01-18 17:30:29'),(321,35,2,'2026-01-18 12:10:39'),(322,129,3,'2026-01-18 12:48:45'),(323,35,1,'2026-01-18 15:02:48'),(324,76,2,'2026-01-18 13:52:50'),(326,115,1,'2026-01-18 09:22:15'),(327,30,1,'2026-01-18 12:48:04'),(328,114,2,'2026-01-18 16:23:34'),(330,30,3,'2026-01-19 09:30:30'),(331,76,1,'2026-01-19 15:02:13'),(333,131,2,'2026-01-19 11:41:39'),(334,104,3,'2026-01-19 15:16:29'),(336,104,3,'2026-01-19 09:21:46'),(337,131,2,'2026-01-19 11:02:33'),(338,8,1,'2026-01-19 09:26:23'),(339,30,3,'2026-01-19 14:06:52'),(341,129,2,'2026-01-19 16:06:50'),(342,105,3,'2026-01-19 13:12:38'),(343,132,1,'2026-01-19 14:59:24'),(344,5,1,'2026-01-19 12:33:06'),(345,129,2,'2026-01-19 14:11:03'),(348,137,1,'2026-01-20 09:04:00'),(349,9,1,'2026-01-20 17:13:16'),(350,102,1,'2026-01-20 16:22:48'),(351,131,2,'2026-01-20 18:19:45'),(352,131,2,'2026-01-20 14:33:18'),(354,104,1,'2026-01-20 10:50:00'),(356,144,1,'2026-01-20 11:01:45'),(357,144,2,'2026-01-20 12:35:51'),(359,28,1,'2026-01-20 10:56:35'),(360,23,2,'2026-01-20 13:34:49'),(361,147,3,'2026-01-21 13:05:42'),(362,105,3,'2026-01-21 15:26:57'),(363,89,1,'2026-01-21 14:08:15'),(365,104,3,'2026-01-21 11:22:00'),(366,105,3,'2026-01-21 09:03:07'),(367,123,2,'2026-01-21 17:28:45'),(368,114,1,'2026-01-21 17:39:17'),(369,106,1,'2026-01-21 13:25:22'),(370,140,2,'2026-01-21 11:39:13'),(372,101,2,'2026-01-21 09:55:02'),(373,8,3,'2026-01-21 10:44:03'),(374,145,1,'2026-01-22 14:10:51'),(375,144,2,'2026-01-22 18:12:01'),(376,76,1,'2026-01-22 12:53:40'),(378,114,2,'2026-01-22 11:06:02'),(380,140,1,'2026-01-22 18:20:33'),(381,23,1,'2026-01-22 14:04:39'),(382,132,1,'2026-01-22 13:54:19'),(383,145,3,'2026-01-22 15:52:59'),(384,140,1,'2026-01-22 18:51:21'),(385,141,1,'2026-01-22 11:10:29'),(386,5,3,'2026-01-22 09:14:49'),(387,37,1,'2026-01-22 12:01:04'),(388,146,2,'2026-01-22 10:47:57'),(390,102,1,'2026-01-22 12:40:56'),(391,148,2,'2026-01-22 11:42:31'),(392,104,1,'2026-01-22 13:07:29'),(393,144,3,'2026-01-22 18:26:15'),(395,144,2,'2026-01-22 15:23:57'),(397,129,2,'2026-01-22 13:24:14'),(398,144,1,'2026-01-22 18:10:42'),(399,125,2,'2026-01-22 16:51:55'),(401,152,2,'2026-01-23 18:02:49'),(402,125,1,'2026-01-23 13:37:42'),(404,157,2,'2026-01-23 15:10:24'),(405,156,3,'2026-01-23 16:33:04'),(408,156,1,'2026-01-23 13:59:09'),(409,23,3,'2026-01-23 12:07:34'),(411,125,1,'2026-01-23 09:01:51'),(412,157,1,'2026-01-23 10:12:20'),(413,140,1,'2026-01-23 13:12:31'),(414,101,2,'2026-01-23 11:51:40'),(418,156,1,'2026-01-23 13:36:38'),(419,28,2,'2026-01-24 15:14:10'),(421,28,1,'2026-01-24 18:02:45'),(422,147,2,'2026-01-24 09:40:31'),(425,24,3,'2026-01-24 11:55:26'),(431,24,1,'2026-01-24 11:10:43'),(433,148,2,'2026-01-24 17:57:03'),(436,24,1,'2026-01-24 18:41:09'),(437,101,1,'2026-01-24 10:11:49'),(441,104,2,'2026-01-25 14:01:39'),(442,148,2,'2026-01-25 09:08:21'),(443,114,3,'2026-01-25 13:15:36'),(444,155,3,'2026-01-25 11:09:34'),(446,145,2,'2026-01-25 11:29:31'),(448,152,3,'2026-01-25 13:39:29'),(449,24,1,'2026-01-25 13:34:03'),(451,23,3,'2026-01-25 13:01:42'),(452,114,2,'2026-01-25 13:26:12'),(454,145,1,'2026-01-25 09:12:37'),(455,162,2,'2026-01-25 10:53:16'),(456,5,1,'2026-01-25 18:11:38'),(457,147,1,'2026-01-25 16:05:48'),(458,24,1,'2026-01-25 10:22:43'),(459,168,2,'2026-01-25 18:29:12'),(460,168,1,'2026-01-25 16:27:02'),(463,168,3,'2026-01-26 12:00:24'),(465,147,3,'2026-01-26 16:01:06'),(468,161,1,'2026-01-26 16:45:47'),(469,171,3,'2026-01-26 11:10:43'),(470,152,2,'2026-01-26 15:07:25'),(471,23,1,'2026-01-26 09:13:33'),(472,172,1,'2026-01-26 09:33:13'),(474,104,1,'2026-01-26 14:10:04'),(475,5,1,'2026-01-26 18:41:40'),(476,173,3,'2026-01-26 15:28:59'),(478,168,3,'2026-01-26 12:34:21'),(480,155,3,'2026-01-26 10:00:33'),(483,140,2,'2026-01-26 13:53:21'),(486,152,2,'2026-01-26 13:08:43'),(487,170,2,'2026-01-26 13:12:07'),(491,173,3,'2026-01-27 18:56:55'),(492,170,1,'2026-01-27 10:27:45'),(495,5,1,'2026-01-27 09:35:55'),(496,23,2,'2026-01-27 14:54:04'),(499,147,2,'2026-01-27 10:45:36'),(501,173,2,'2026-01-27 16:35:35'),(503,161,3,'2026-01-28 17:33:32'),(504,104,3,'2026-01-28 10:51:52'),(507,173,1,'2026-01-28 16:22:24'),(508,147,3,'2026-01-28 13:59:23'),(512,181,2,'2026-01-28 10:06:39'),(517,168,2,'2026-01-28 10:44:05'),(519,155,2,'2026-01-29 14:03:51'),(520,140,1,'2026-01-29 10:04:01'),(521,173,1,'2026-01-29 16:59:01'),(522,147,2,'2026-01-29 12:28:48'),(524,155,1,'2026-01-29 10:09:45'),(525,155,2,'2026-01-29 18:36:29'),(526,23,2,'2026-01-29 14:54:43'),(527,173,1,'2026-01-29 11:36:35'),(529,177,3,'2026-01-29 12:47:29'),(530,156,1,'2026-01-29 11:46:08'),(531,161,1,'2026-01-30 12:09:14'),(534,181,1,'2026-01-30 16:50:07'),(536,181,3,'2026-01-30 09:10:17'),(538,145,3,'2026-01-30 09:46:44'),(541,162,2,'2026-01-30 13:37:37'),(543,155,2,'2026-01-30 13:47:03'),(545,191,3,'2026-01-31 14:18:18'),(546,177,1,'2026-01-31 15:49:49'),(547,23,2,'2026-01-31 12:58:50'),(548,190,2,'2026-01-31 12:43:59'),(549,190,1,'2026-01-31 14:49:14'),(551,145,3,'2026-01-31 12:01:04'),(556,156,1,'2026-01-31 11:03:23'),(557,181,2,'2026-01-31 09:04:59'),(559,168,2,'2026-01-31 17:37:05'),(560,181,3,'2026-01-31 11:09:53'),(561,188,2,'2026-01-31 13:05:27'),(562,147,1,'2026-01-31 12:04:06'),(563,191,1,'2026-01-31 09:48:03'),(565,173,3,'2026-02-01 09:10:50'),(566,168,2,'2026-02-01 16:26:28'),(571,155,1,'2026-02-01 16:48:41'),(574,177,1,'2026-02-01 18:50:37'),(575,196,3,'2026-02-01 17:34:23'),(579,161,1,'2026-02-02 12:27:55'),(581,145,2,'2026-02-02 10:12:34'),(584,195,1,'2026-02-02 16:48:07'),(585,188,1,'2026-02-02 10:22:07'),(586,177,2,'2026-02-02 13:23:43'),(587,168,2,'2026-02-02 12:16:39'),(588,190,1,'2026-02-02 16:01:15'),(590,155,2,'2026-02-02 15:28:06'),(592,145,1,'2026-02-03 15:49:03'),(593,201,3,'2026-02-03 16:38:03'),(596,145,1,'2026-02-03 13:01:31'),(598,173,3,'2026-02-03 12:02:45'),(599,195,1,'2026-02-03 13:18:58'),(600,156,1,'2026-02-03 13:43:43'),(601,168,3,'2026-02-03 09:19:23'),(604,200,2,'2026-02-03 12:03:33'),(608,168,2,'2026-02-04 09:34:33'),(609,201,1,'2026-02-04 18:25:30'),(610,155,2,'2026-02-04 13:37:00'),(614,145,1,'2026-02-04 17:29:09'),(616,168,2,'2026-02-04 15:22:13'),(617,196,2,'2026-02-04 09:01:11'),(618,202,2,'2026-02-04 10:15:54'),(620,202,2,'2026-02-04 12:22:23'),(622,201,2,'2026-02-04 11:56:26'),(623,202,2,'2026-02-04 16:01:59'),(626,173,3,'2026-02-04 18:31:23'),(628,201,1,'2026-02-04 18:03:53'),(634,215,3,'2026-02-05 09:24:34'),(635,215,3,'2026-02-05 13:57:24'),(636,208,2,'2026-02-05 12:42:49'),(637,214,1,'2026-02-05 11:05:23'),(639,208,1,'2026-02-05 10:05:06'),(645,208,3,'2026-02-05 16:36:48'),(648,210,3,'2026-02-06 18:34:27'),(649,145,2,'2026-02-06 14:56:53'),(651,200,1,'2026-02-06 11:57:51'),(653,155,1,'2026-02-06 12:46:24'),(654,200,1,'2026-02-06 09:39:36'),(655,168,3,'2026-02-06 14:20:30'),(656,173,1,'2026-02-06 11:33:50'),(657,210,1,'2026-02-06 14:33:35'),(658,215,3,'2026-02-06 13:58:12'),(659,168,1,'2026-02-06 12:42:29'),(660,215,1,'2026-02-06 09:54:19'),(661,219,2,'2026-02-07 11:08:33'),(663,173,1,'2026-02-07 18:13:12'),(664,218,3,'2026-02-07 16:46:14'),(666,214,1,'2026-02-07 09:44:29'),(668,217,3,'2026-02-07 14:12:11'),(670,145,2,'2026-02-07 15:47:00'),(672,217,3,'2026-02-07 13:34:50'),(673,145,3,'2026-02-07 18:32:07'),(675,200,2,'2026-02-07 14:13:13'),(676,217,1,'2026-02-07 17:53:56'),(677,214,2,'2026-02-07 17:22:46'),(679,200,2,'2026-02-07 14:32:38'),(685,216,1,'2026-02-07 13:22:57'),(686,200,1,'2026-02-07 10:18:09'),(690,145,2,'2026-02-08 17:03:12'),(692,226,1,'2026-02-08 16:09:21'),(693,145,1,'2026-02-08 10:57:29'),(694,225,1,'2026-02-08 15:55:17'),(695,145,3,'2026-02-08 09:05:49'),(696,216,1,'2026-02-08 14:28:29'),(699,226,1,'2026-02-08 17:20:50'),(703,227,1,'2026-02-09 10:33:32'),(704,215,3,'2026-02-09 09:42:57'),(706,202,3,'2026-02-09 11:04:10'),(707,227,2,'2026-02-09 18:35:16'),(709,227,3,'2026-02-09 09:15:32'),(711,226,1,'2026-02-09 12:23:54'),(712,219,1,'2026-02-09 18:24:05'),(714,224,3,'2026-02-09 09:46:13'),(715,202,2,'2026-02-09 18:56:23'),(716,215,1,'2026-02-09 16:50:17'),(720,227,3,'2026-02-09 09:49:31'),(721,202,3,'2026-02-09 17:59:31'),(726,227,2,'2026-02-10 13:03:30'),(728,202,3,'2026-02-10 16:43:14'),(731,240,1,'2026-02-10 09:34:08'),(734,215,1,'2026-02-10 16:03:52'),(735,233,1,'2026-02-10 09:26:50'),(737,240,2,'2026-02-10 13:14:03'),(738,239,2,'2026-02-10 15:52:01'),(740,239,3,'2026-02-10 14:44:37'),(741,215,1,'2026-02-10 13:54:16'),(750,224,1,'2026-02-11 16:21:12'),(751,242,2,'2026-02-11 15:33:09'),(753,242,1,'2026-02-11 12:35:47'),(758,240,2,'2026-02-11 09:26:08'),(760,202,3,'2026-02-11 11:24:57'),(762,239,2,'2026-02-11 13:44:49'),(763,145,1,'2026-02-11 16:16:58'),(767,227,1,'2026-02-12 12:10:49'),(768,145,1,'2026-02-12 18:20:52'),(769,202,1,'2026-02-12 11:38:08'),(770,214,1,'2026-02-12 15:25:51'),(771,227,1,'2026-02-12 14:00:03'),(776,241,3,'2026-02-12 13:49:52'),(781,202,2,'2026-02-12 17:40:09'),(783,241,3,'2026-02-12 11:06:36'),(784,233,1,'2026-02-12 10:26:33'),(787,233,2,'2026-02-13 12:50:06'),(788,252,2,'2026-02-13 15:03:23'),(792,214,2,'2026-02-13 11:58:11'),(796,256,2,'2026-02-13 10:38:22'),(799,214,2,'2026-02-13 10:40:59'),(801,256,1,'2026-02-13 14:41:24'),(804,227,2,'2026-02-13 11:48:55'),(805,227,2,'2026-02-13 16:26:07'),(809,252,2,'2026-02-14 18:08:08'),(811,260,2,'2026-02-14 16:54:48'),(813,260,2,'2026-02-14 13:36:55'),(814,227,3,'2026-02-14 13:33:06'),(816,260,1,'2026-02-14 16:11:07'),(819,252,1,'2026-02-14 12:57:46'),(821,241,1,'2026-02-14 18:02:17'),(823,239,1,'2026-02-14 15:44:02'),(827,227,3,'2026-02-14 15:13:33'),(829,227,2,'2026-02-14 15:56:18'),(830,241,1,'2026-02-15 13:53:44'),(832,233,2,'2026-02-15 13:26:13'),(833,145,3,'2026-02-15 17:14:59'),(834,262,3,'2026-02-15 12:52:28'),(836,233,2,'2026-02-15 18:39:06'),(837,239,3,'2026-02-15 17:08:33'),(838,255,3,'2026-02-15 18:18:45'),(840,255,2,'2026-02-15 13:58:09'),(844,227,2,'2026-02-16 17:22:13'),(849,227,2,'2026-02-16 09:44:22'),(853,260,1,'2026-02-16 09:11:45'),(854,260,1,'2026-02-16 14:50:11'),(855,252,1,'2026-02-16 13:36:09'),(856,254,1,'2026-02-16 15:03:42'),(859,241,3,'2026-02-16 18:08:51'),(865,252,2,'2026-02-16 10:10:38'),(873,233,1,'2026-02-17 13:22:27'),(875,270,2,'2026-02-17 11:30:39'),(877,254,1,'2026-02-17 12:36:02'),(879,270,1,'2026-02-17 09:07:31'),(882,239,3,'2026-02-17 17:19:15'),(883,227,3,'2026-02-17 15:57:49'),(885,252,1,'2026-02-17 13:19:05'),(886,145,3,'2026-02-17 10:33:34'),(889,241,2,'2026-02-17 11:10:45'),(890,275,2,'2026-02-18 18:57:27'),(893,233,1,'2026-02-18 13:22:47'),(895,252,2,'2026-02-18 17:27:26'),(896,269,1,'2026-02-18 11:07:35'),(897,233,2,'2026-02-18 09:16:33'),(898,145,1,'2026-02-18 09:16:01'),(902,269,3,'2026-02-18 18:36:39'),(903,227,2,'2026-02-18 16:39:37'),(905,273,1,'2026-02-18 18:59:39'),(908,274,2,'2026-02-18 12:26:41'),(910,241,2,'2026-02-18 10:57:23'),(912,233,2,'2026-02-19 16:35:12'),(913,282,2,'2026-02-19 09:24:18'),(914,239,1,'2026-02-19 16:09:21'),(915,283,1,'2026-02-19 11:44:34'),(917,275,2,'2026-02-19 14:36:36'),(919,269,1,'2026-02-19 17:38:57'),(923,274,1,'2026-02-19 14:50:51'),(924,227,3,'2026-02-19 12:49:30'),(925,286,2,'2026-02-19 18:00:53'),(926,275,2,'2026-02-19 14:35:40'),(927,145,3,'2026-02-19 13:04:52'),(930,282,2,'2026-02-20 14:24:56'),(932,281,2,'2026-02-20 18:50:21'),(934,284,2,'2026-02-20 18:36:30'),(937,275,2,'2026-02-20 16:18:41'),(939,283,2,'2026-02-20 14:45:26'),(940,239,2,'2026-02-20 16:10:39'),(941,275,2,'2026-02-20 16:23:55'),(945,227,1,'2026-02-20 11:36:22'),(949,274,2,'2026-02-21 10:19:52'),(951,269,2,'2026-02-21 11:47:18'),(952,282,2,'2026-02-21 17:55:29'),(953,275,3,'2026-02-21 11:27:57'),(954,275,2,'2026-02-21 13:10:19'),(955,275,2,'2026-02-21 17:00:39'),(957,239,1,'2026-02-21 15:06:15'),(958,274,2,'2026-02-21 14:24:55'),(959,274,1,'2026-02-21 16:28:26'),(960,281,2,'2026-02-21 13:07:21'),(963,281,3,'2026-02-21 14:42:28'),(965,241,3,'2026-02-21 17:05:52'),(967,241,1,'2026-02-21 18:07:45'),(968,275,2,'2026-02-21 15:35:03'),(970,283,3,'2026-02-22 18:51:39'),(972,292,1,'2026-02-22 15:42:21'),(973,292,1,'2026-02-22 15:57:55'),(974,283,1,'2026-02-22 09:50:36'),(979,290,1,'2026-02-22 13:24:17'),(980,241,1,'2026-02-22 09:17:59'),(981,286,1,'2026-02-23 13:04:20'),(983,275,1,'2026-02-23 11:31:11'),(984,281,1,'2026-02-23 14:21:26'),(986,285,2,'2026-02-23 12:19:18'),(989,297,1,'2026-02-23 16:44:38'),(991,286,2,'2026-02-23 10:59:05'),(993,269,3,'2026-02-23 17:45:41'),(994,145,1,'2026-02-23 10:29:54'),(997,284,1,'2026-02-23 16:11:09'),(998,274,3,'2026-02-23 17:44:59'),(999,292,1,'2026-02-23 09:51:58'),(1000,274,3,'2026-02-24 11:30:45'),(1001,145,1,'2026-02-24 16:52:31'),(1003,274,3,'2026-02-24 16:59:17'),(1005,292,1,'2026-02-24 17:35:05'),(1009,301,3,'2026-02-24 10:10:44'),(1014,297,2,'2026-02-24 17:33:36'),(1016,301,2,'2026-02-24 12:36:26'),(1017,283,2,'2026-02-24 10:05:41'),(1018,305,1,'2026-02-24 09:14:25'),(1019,275,2,'2026-02-25 18:26:27'),(1020,307,3,'2026-02-25 18:25:15'),(1021,303,2,'2026-02-25 16:54:08'),(1022,305,2,'2026-02-25 17:30:52'),(1023,301,2,'2026-02-25 09:41:20'),(1026,300,1,'2026-02-25 10:14:36'),(1028,269,1,'2026-02-25 12:33:58'),(1031,303,1,'2026-02-25 15:46:31'),(1032,300,3,'2026-02-25 09:52:44'),(1033,303,2,'2026-02-25 14:59:49'),(1035,307,3,'2026-02-25 12:05:51'),(1036,292,1,'2026-02-25 09:38:58'),(1037,302,1,'2026-02-25 09:17:21'),(1042,227,1,'2026-02-26 17:43:56'),(1043,307,1,'2026-02-26 12:08:32'),(1045,300,2,'2026-02-26 15:54:05'),(1054,305,1,'2026-02-26 15:38:46'),(1055,305,1,'2026-02-26 12:38:20'),(1059,292,2,'2026-02-26 10:08:42'),(1061,292,1,'2026-02-26 10:51:00'),(1063,311,2,'2026-02-27 15:03:11'),(1064,308,1,'2026-02-27 18:38:05'),(1066,269,1,'2026-02-27 11:21:16'),(1072,292,2,'2026-02-27 10:34:56'),(1073,311,1,'2026-02-27 13:06:36'),(1075,312,1,'2026-02-27 12:46:31'),(1078,227,2,'2026-02-28 11:55:13'),(1079,304,3,'2026-02-28 09:10:37'),(1080,302,2,'2026-02-28 11:58:35'),(1084,292,3,'2026-02-28 18:25:00'),(1085,324,1,'2026-02-28 12:06:54'),(1086,275,1,'2026-02-28 14:04:31'),(1087,324,1,'2026-02-28 09:02:02'),(1088,312,3,'2026-02-28 13:36:39'),(1089,312,3,'2026-02-28 16:33:49'),(1090,300,2,'2026-02-28 15:10:24'),(1091,307,2,'2026-02-28 14:30:48'),(1092,322,2,'2026-02-28 17:17:36'),(1095,300,2,'2026-02-28 10:30:25'),(1098,321,2,'2026-02-28 13:19:50'),(1100,328,1,'2026-03-01 10:19:30'),(1102,327,2,'2026-03-01 11:18:22'),(1106,269,2,'2026-03-01 09:08:58'),(1108,327,2,'2026-03-01 18:55:51'),(1111,322,1,'2026-03-01 09:59:55'),(1119,327,1,'2026-03-01 17:37:29'),(1120,311,3,'2026-03-01 15:24:24'),(1121,322,2,'2026-03-01 14:30:54'),(1122,269,3,'2026-03-02 15:49:14'),(1126,303,1,'2026-03-02 11:23:04'),(1127,328,2,'2026-03-02 15:32:43'),(1129,322,3,'2026-03-02 11:12:43'),(1135,338,2,'2026-03-03 10:58:56'),(1140,324,1,'2026-03-03 11:03:26'),(1144,307,3,'2026-03-03 10:41:37'),(1148,275,1,'2026-03-04 15:37:54'),(1149,334,2,'2026-03-04 09:12:23'),(1152,324,3,'2026-03-04 14:15:52'),(1153,307,1,'2026-03-04 12:36:53'),(1155,302,2,'2026-03-04 15:01:56'),(1156,302,1,'2026-03-04 16:29:54'),(1158,307,3,'2026-03-04 14:48:37'),(1160,307,1,'2026-03-04 13:46:16'),(1161,334,3,'2026-03-04 15:24:56'),(1162,334,2,'2026-03-04 13:07:10'),(1163,322,3,'2026-03-04 16:47:28'),(1164,312,1,'2026-03-04 11:02:13'),(1166,338,2,'2026-03-04 11:35:15'),(1167,335,1,'2026-03-04 12:46:19'),(1168,336,1,'2026-03-04 11:34:52'),(1171,335,2,'2026-03-04 18:56:42'),(1173,324,2,'2026-03-04 10:51:57'),(1175,343,3,'2026-03-05 09:46:38'),(1176,335,1,'2026-03-05 17:34:46'),(1177,302,1,'2026-03-05 17:19:29'),(1179,312,1,'2026-03-05 15:31:10'),(1181,336,1,'2026-03-05 14:13:46'),(1182,337,3,'2026-03-05 17:13:25'),(1184,344,1,'2026-03-05 11:00:37'),(1185,322,3,'2026-03-05 12:05:02'),(1186,302,1,'2026-03-05 13:22:38'),(1188,344,3,'2026-03-05 09:11:07'),(1189,227,1,'2026-03-05 15:41:11'),(1192,334,2,'2026-03-05 13:35:04'),(1193,275,3,'2026-03-05 18:50:59'),(1200,343,1,'2026-03-06 12:09:26'),(1201,345,2,'2026-03-06 14:49:03'),(1204,324,2,'2026-03-06 13:27:33'),(1207,275,2,'2026-03-06 09:26:09'),(1208,345,3,'2026-03-06 15:59:03'),(1211,227,2,'2026-03-06 11:50:33'),(1212,307,1,'2026-03-06 18:46:14'),(1213,335,1,'2026-03-06 17:48:30'),(1215,275,3,'2026-03-06 13:02:10'),(1217,322,1,'2026-03-06 13:49:33'),(1218,343,3,'2026-03-06 16:38:14'),(1220,350,1,'2026-03-07 14:11:57'),(1225,312,1,'2026-03-07 18:50:25'),(1226,343,1,'2026-03-07 18:50:21'),(1228,275,1,'2026-03-07 10:08:07'),(1229,322,1,'2026-03-07 11:27:25'),(1230,344,3,'2026-03-07 18:25:49'),(1233,227,1,'2026-03-07 09:31:32'),(1235,357,1,'2026-03-08 15:20:22'),(1238,312,3,'2026-03-08 12:17:10'),(1239,324,2,'2026-03-08 11:43:24'),(1243,324,3,'2026-03-08 10:19:34'),(1244,312,1,'2026-03-08 14:20:30'),(1245,324,2,'2026-03-08 14:50:21'),(1246,312,1,'2026-03-08 11:38:38'),(1248,344,1,'2026-03-08 09:41:42'),(1249,312,1,'2026-03-08 14:09:56'),(1251,346,1,'2026-03-09 12:36:41'),(1253,360,2,'2026-03-09 11:02:31'),(1255,362,2,'2026-03-09 13:05:28'),(1257,364,2,'2026-03-09 16:26:07'),(1260,345,2,'2026-03-09 17:23:46'),(1262,312,3,'2026-03-09 11:34:55'),(1263,364,2,'2026-03-09 16:22:30'),(1265,312,2,'2026-03-09 09:52:59'),(1269,360,3,'2026-03-10 16:25:38'),(1272,364,1,'2026-03-10 18:33:13'),(1273,350,3,'2026-03-10 12:45:00'),(1279,360,3,'2026-03-10 16:00:31'),(1282,350,1,'2026-03-10 16:52:35'),(1284,350,3,'2026-03-10 18:06:15'),(1285,275,1,'2026-03-10 17:18:15'),(1287,360,2,'2026-03-10 12:48:14'),(1289,275,1,'2026-03-11 17:05:20'),(1290,275,1,'2026-03-11 18:48:14'),(1291,345,1,'2026-03-11 15:18:56'),(1293,361,1,'2026-03-11 12:46:29'),(1295,367,1,'2026-03-11 09:52:10'),(1296,364,2,'2026-03-11 10:18:29'),(1298,346,1,'2026-03-11 10:11:08'),(1303,363,3,'2026-03-11 18:12:58'),(1304,364,1,'2026-03-12 16:15:10'),(1306,364,2,'2026-03-12 16:39:33'),(1308,345,1,'2026-03-12 12:53:01'),(1309,346,1,'2026-03-12 17:32:49'),(1310,366,2,'2026-03-12 14:48:08'),(1313,361,3,'2026-03-12 16:58:20'),(1318,364,3,'2026-03-12 18:41:19'),(1319,363,2,'2026-03-12 13:26:17'),(1321,345,2,'2026-03-12 17:59:27'),(1322,371,2,'2026-03-12 16:29:43'),(1324,365,3,'2026-03-12 13:52:40'),(1325,350,1,'2026-03-12 09:36:18'),(1327,360,2,'2026-03-12 15:23:19'),(1328,366,3,'2026-03-12 15:23:34'),(1329,366,3,'2026-03-13 18:39:16'),(1330,365,1,'2026-03-13 12:18:34'),(1331,383,1,'2026-03-13 10:30:18'),(1332,366,2,'2026-03-13 10:44:42'),(1333,360,1,'2026-03-13 10:28:24'),(1337,382,1,'2026-03-13 13:14:36'),(1338,371,2,'2026-03-13 18:16:25'),(1340,364,3,'2026-03-13 16:40:36'),(1342,345,2,'2026-03-13 17:54:56'),(1345,371,2,'2026-03-13 13:48:22'),(1352,275,2,'2026-03-13 14:17:02'),(1353,365,3,'2026-03-14 11:41:25'),(1354,360,3,'2026-03-14 13:43:46'),(1355,365,3,'2026-03-14 16:51:31'),(1358,350,3,'2026-03-14 12:19:16'),(1359,275,2,'2026-03-14 14:20:12'),(1368,345,3,'2026-03-14 11:02:22'),(1371,388,2,'2026-03-14 12:47:54'),(1372,383,2,'2026-03-14 15:17:21'),(1374,383,3,'2026-03-15 12:38:30'),(1376,392,1,'2026-03-15 10:07:06'),(1378,275,1,'2026-03-15 12:21:15'),(1379,391,2,'2026-03-15 16:55:18'),(1380,388,1,'2026-03-15 15:04:31'),(1381,364,1,'2026-03-15 18:46:02'),(1383,383,3,'2026-03-15 10:41:07'),(1384,345,1,'2026-03-15 09:10:58'),(1385,390,3,'2026-03-15 14:04:53'),(1389,275,1,'2026-03-15 17:34:23'),(1390,391,1,'2026-03-15 14:33:57'),(1391,387,2,'2026-03-15 18:39:30'),(1397,364,3,'2026-03-15 18:45:21'),(1398,388,3,'2026-03-15 12:50:29'),(1400,399,3,'2026-03-16 14:51:56'),(1401,389,1,'2026-03-16 18:29:08'),(1402,399,2,'2026-03-16 10:56:45'),(1403,383,1,'2026-03-16 13:24:04'),(1407,383,2,'2026-03-16 13:20:37'),(1409,387,2,'2026-03-16 14:26:28'),(1411,360,2,'2026-03-16 11:19:59'),(1412,387,2,'2026-03-16 11:03:31'),(1413,275,2,'2026-03-16 09:21:07'),(1414,389,3,'2026-03-16 16:40:08'),(1416,383,1,'2026-03-17 15:14:32'),(1417,402,1,'2026-03-17 13:11:40'),(1420,388,1,'2026-03-17 16:02:07'),(1421,397,1,'2026-03-17 13:46:59'),(1424,388,3,'2026-03-17 11:36:00'),(1426,388,1,'2026-03-17 09:18:07'),(1428,403,1,'2026-03-17 10:42:40'),(1429,399,1,'2026-03-17 11:47:31'),(1430,350,1,'2026-03-17 10:25:38'),(1431,350,2,'2026-03-17 12:13:07'),(1433,389,2,'2026-03-17 09:28:54'),(1434,388,3,'2026-03-17 09:45:05'),(1435,390,2,'2026-03-17 10:10:48'),(1437,360,1,'2026-03-17 15:40:13'),(1438,388,2,'2026-03-17 12:16:30'),(1439,396,2,'2026-03-17 15:30:21'),(1440,397,2,'2026-03-17 12:55:10'),(1441,390,1,'2026-03-18 15:42:58'),(1447,397,2,'2026-03-18 15:49:12'),(1449,402,1,'2026-03-18 12:36:18'),(1450,397,2,'2026-03-18 16:27:44'),(1452,399,1,'2026-03-18 18:35:51'),(1453,398,1,'2026-03-18 16:42:13'),(1454,388,1,'2026-03-19 09:59:09'),(1457,350,3,'2026-03-19 18:33:46'),(1458,388,1,'2026-03-19 12:41:08'),(1459,415,2,'2026-03-19 12:57:14'),(1463,402,1,'2026-03-19 10:39:45'),(1470,415,2,'2026-03-20 15:16:16'),(1471,396,2,'2026-03-20 17:12:49'),(1472,350,2,'2026-03-20 13:01:57'),(1473,415,3,'2026-03-20 09:21:34'),(1475,350,3,'2026-03-20 17:47:39'),(1477,397,2,'2026-03-20 10:27:39'),(1480,420,2,'2026-03-20 13:19:55'),(1484,350,2,'2026-03-20 16:23:02'),(1485,397,2,'2026-03-20 11:36:12'),(1486,419,3,'2026-03-20 12:08:39'),(1487,420,2,'2026-03-20 15:33:31'),(1488,390,3,'2026-03-21 12:02:51'),(1493,415,1,'2026-03-21 15:19:08'),(1497,350,2,'2026-03-21 14:03:20'),(1498,402,1,'2026-03-21 10:46:37'),(1500,416,3,'2026-03-21 09:26:14'),(1505,402,2,'2026-03-22 16:08:36'),(1506,430,3,'2026-03-22 17:56:08'),(1507,419,2,'2026-03-22 14:05:50'),(1511,415,1,'2026-03-22 12:49:29'),(1516,415,1,'2026-03-22 14:57:52'),(1519,350,1,'2026-03-22 13:02:54'),(1525,434,3,'2026-03-23 15:50:42'),(1526,404,2,'2026-03-23 16:20:16'),(1527,390,2,'2026-03-23 15:19:15'),(1533,430,3,'2026-03-24 10:27:40'),(1536,390,2,'2026-03-24 15:37:05'),(1546,390,3,'2026-03-24 12:09:14'),(1548,399,2,'2026-03-24 13:10:52'),(1549,415,2,'2026-03-24 17:58:02'),(1553,430,2,'2026-03-24 14:06:04'),(1561,415,1,'2026-03-25 10:56:56'),(1562,443,2,'2026-03-25 16:24:54'),(1564,428,2,'2026-03-25 17:16:54'),(1568,390,3,'2026-03-25 10:52:00'),(1572,396,2,'2026-03-25 18:15:55'),(1573,390,1,'2026-03-25 12:51:30'),(1575,445,2,'2026-03-26 10:36:17'),(1577,350,2,'2026-03-26 17:16:06'),(1580,428,1,'2026-03-26 16:35:41'),(1581,443,3,'2026-03-26 12:09:23'),(1584,445,1,'2026-03-26 18:45:04'),(1585,428,3,'2026-03-26 17:19:40'),(1590,396,3,'2026-03-26 12:45:14'),(1592,350,2,'2026-03-26 15:17:40'),(1594,444,2,'2026-03-26 13:07:41'),(1595,399,2,'2026-03-26 14:39:05'),(1597,437,1,'2026-03-27 10:09:53'),(1598,415,1,'2026-03-27 14:31:09'),(1603,443,3,'2026-03-27 13:34:07'),(1605,350,1,'2026-03-27 11:08:27'),(1606,396,2,'2026-03-27 17:46:28'),(1607,444,2,'2026-03-27 09:02:15'),(1608,452,1,'2026-03-27 15:47:49'),(1611,433,1,'2026-03-27 09:25:56'),(1614,399,1,'2026-03-27 13:32:05'),(1622,399,3,'2026-03-28 17:58:32'),(1623,457,2,'2026-03-28 14:33:27'),(1625,450,2,'2026-03-28 18:38:55'),(1627,446,1,'2026-03-28 14:31:15'),(1629,428,2,'2026-03-28 16:42:12'),(1630,451,2,'2026-03-28 14:26:22'),(1631,415,3,'2026-03-28 14:00:46'),(1632,446,3,'2026-03-28 18:29:29'),(1633,450,3,'2026-03-28 12:19:24'),(1634,350,3,'2026-03-28 11:06:29'),(1635,450,2,'2026-03-28 17:39:07'),(1636,450,2,'2026-03-28 14:40:12'),(1637,399,1,'2026-03-28 16:01:13'),(1639,446,2,'2026-03-28 10:20:31'),(1640,415,1,'2026-03-28 11:00:22'),(1644,461,2,'2026-03-29 14:49:08'),(1646,462,2,'2026-03-29 14:40:50'),(1650,350,3,'2026-03-29 10:52:53'),(1652,447,2,'2026-03-29 18:48:08'),(1653,462,1,'2026-03-29 16:51:47'),(1656,428,2,'2026-03-29 13:09:09'),(1657,399,2,'2026-03-29 18:35:14'),(1658,446,1,'2026-03-29 18:09:48'),(1660,451,1,'2026-03-29 09:26:01'),(1662,463,2,'2026-03-29 15:38:57'),(1664,447,2,'2026-03-29 13:54:09'),(1665,447,3,'2026-03-29 16:49:04'),(1668,461,3,'2026-03-30 15:58:16'),(1669,451,3,'2026-03-30 15:48:38'),(1670,450,1,'2026-03-30 12:45:56'),(1672,451,2,'2026-03-30 13:26:22'),(1673,446,3,'2026-03-30 10:22:52'),(1676,467,3,'2026-03-30 12:13:30'),(1679,444,1,'2026-03-30 18:17:10'),(1680,399,2,'2026-03-30 13:54:52'),(1683,350,1,'2026-03-30 17:11:28'),(1684,461,3,'2026-03-30 18:11:31'),(1685,467,1,'2026-03-30 12:49:07'),(1686,468,1,'2026-03-30 15:09:06'),(1688,399,1,'2026-03-30 18:47:31'),(1698,399,1,'2026-03-31 14:30:58'),(1700,446,2,'2026-03-31 09:36:36'),(1703,443,3,'2026-03-31 12:41:01'),(1705,446,1,'2026-03-31 12:47:24'),(1711,475,3,'2026-04-01 18:00:57'),(1712,478,1,'2026-04-01 17:42:27'),(1713,447,3,'2026-04-01 14:34:33'),(1715,350,1,'2026-04-01 13:48:27'),(1716,475,1,'2026-04-01 10:54:55'),(1720,447,2,'2026-04-01 14:29:17'),(1721,477,2,'2026-04-01 13:21:44'),(1722,447,1,'2026-04-01 18:23:08'),(1723,476,1,'2026-04-01 11:52:51'),(1725,443,3,'2026-04-01 10:44:34'),(1726,475,1,'2026-04-01 10:13:05'),(1727,447,1,'2026-04-01 10:26:22'),(1729,443,2,'2026-04-01 18:03:34'),(1732,475,2,'2026-04-01 14:54:10'),(1736,446,3,'2026-04-01 12:24:16'),(1737,474,1,'2026-04-01 14:33:11'),(1739,474,1,'2026-04-02 09:03:06'),(1741,483,3,'2026-04-02 17:55:10'),(1742,483,1,'2026-04-02 18:49:17'),(1744,474,2,'2026-04-02 10:22:10'),(1746,478,3,'2026-04-02 12:55:11'),(1749,483,2,'2026-04-02 12:54:03'),(1750,350,1,'2026-04-02 10:03:24'),(1751,474,1,'2026-04-02 10:59:48'),(1753,482,1,'2026-04-02 12:00:29'),(1755,483,1,'2026-04-02 09:40:43'),(1756,483,1,'2026-04-02 11:46:01'),(1758,476,2,'2026-04-02 17:10:00'),(1761,483,1,'2026-04-03 16:03:05'),(1764,443,2,'2026-04-03 14:27:02'),(1766,443,1,'2026-04-03 09:35:22'),(1769,482,2,'2026-04-03 18:20:52'),(1775,474,2,'2026-04-04 15:59:40'),(1777,489,3,'2026-04-04 17:18:19'),(1780,463,1,'2026-04-04 14:08:32'),(1781,482,1,'2026-04-04 18:42:39'),(1782,478,2,'2026-04-04 13:47:26'),(1783,474,1,'2026-04-04 09:01:09'),(1784,495,1,'2026-04-04 13:52:07'),(1785,478,2,'2026-04-04 10:51:23'),(1791,463,3,'2026-04-04 13:54:29'),(1794,478,2,'2026-04-04 13:20:09'),(1795,478,2,'2026-04-04 15:06:21'),(1798,489,1,'2026-04-05 16:50:58'),(1800,490,3,'2026-04-05 10:38:05'),(1801,483,2,'2026-04-05 17:15:42'),(1802,494,1,'2026-04-05 12:24:40'),(1804,482,1,'2026-04-05 12:42:59'),(1808,490,2,'2026-04-05 14:47:17'),(1809,500,3,'2026-04-05 11:39:58'),(1813,483,3,'2026-04-05 13:34:25'),(1816,506,3,'2026-04-06 10:35:06'),(1819,508,2,'2026-04-06 10:44:30'),(1820,500,2,'2026-04-06 16:12:41'),(1821,509,3,'2026-04-06 13:59:38'),(1822,478,3,'2026-04-06 10:16:19'),(1823,507,1,'2026-04-06 16:18:58'),(1826,483,1,'2026-04-06 15:27:50'),(1827,482,1,'2026-04-06 12:00:28'),(1830,496,2,'2026-04-06 13:46:45'),(1833,508,2,'2026-04-07 14:42:06'),(1834,506,2,'2026-04-07 09:27:35'),(1835,494,2,'2026-04-07 17:13:02'),(1836,500,3,'2026-04-07 11:08:15'),(1838,478,2,'2026-04-07 15:08:18'),(1839,506,2,'2026-04-07 10:29:24'),(1842,494,3,'2026-04-07 13:41:53'),(1843,507,1,'2026-04-07 10:01:20'),(1846,482,2,'2026-04-07 18:42:51'),(1848,482,2,'2026-04-08 12:53:06'),(1851,463,2,'2026-04-08 11:03:26'),(1854,506,3,'2026-04-08 09:58:01'),(1855,494,3,'2026-04-08 10:47:26'),(1856,507,2,'2026-04-08 18:34:12'),(1868,463,2,'2026-04-08 09:15:17'),(1870,524,2,'2026-04-09 11:11:48'),(1874,506,1,'2026-04-09 09:21:49'),(1876,524,1,'2026-04-09 11:56:59'),(1877,524,1,'2026-04-09 16:54:07'),(1878,522,2,'2026-04-09 15:06:37'),(1882,517,2,'2026-04-09 12:01:52'),(1884,500,2,'2026-04-09 17:07:28'),(1885,500,1,'2026-04-09 14:19:58'),(1889,524,2,'2026-04-10 11:58:17'),(1893,523,2,'2026-04-10 17:40:00'),(1896,507,1,'2026-04-10 18:57:05'),(1899,463,3,'2026-04-10 10:40:50'),(1900,522,3,'2026-04-10 10:59:16'),(1909,463,3,'2026-04-11 16:58:12'),(1910,482,2,'2026-04-11 18:28:26'),(1911,500,3,'2026-04-11 13:56:30'),(1918,463,2,'2026-04-11 09:15:11'),(1919,500,1,'2026-04-11 15:33:15'),(1920,482,3,'2026-04-11 11:13:57'),(1922,507,3,'2026-04-12 09:40:02'),(1924,518,2,'2026-04-12 16:55:01'),(1927,522,3,'2026-04-12 13:56:48'),(1930,517,1,'2026-04-12 15:40:13'),(1931,482,2,'2026-04-12 12:11:08'),(1932,516,2,'2026-04-12 13:30:09'),(1933,531,1,'2026-04-12 15:59:50'),(1935,537,2,'2026-04-13 11:30:17'),(1941,516,1,'2026-04-13 12:34:09'),(1942,519,1,'2026-04-13 14:24:47'),(1943,463,3,'2026-04-13 16:03:57'),(1944,538,1,'2026-04-13 10:10:24'),(1945,463,2,'2026-04-13 15:18:15'),(1949,522,1,'2026-04-13 14:45:10'),(1953,500,3,'2026-04-13 10:35:44'),(1954,536,2,'2026-04-13 16:01:02'),(1957,538,1,'2026-04-13 13:41:07'),(1959,519,1,'2026-04-13 17:47:49'),(1961,500,2,'2026-04-14 17:02:24'),(1962,500,1,'2026-04-14 12:37:25'),(1963,522,2,'2026-04-14 17:14:30'),(1965,537,1,'2026-04-14 09:50:59'),(1969,542,2,'2026-04-14 17:13:12'),(1971,537,1,'2026-04-14 14:36:23'),(1975,531,1,'2026-04-14 13:37:04'),(1980,541,1,'2026-04-14 12:34:33'),(1982,500,3,'2026-04-14 17:31:43'),(1985,500,3,'2026-04-14 15:37:31'),(1986,531,2,'2026-04-14 16:18:54'),(1990,500,1,'2026-04-15 13:18:11'),(1994,546,2,'2026-04-15 12:02:19'),(1998,543,1,'2026-04-15 17:57:57'),(2000,541,2,'2026-04-15 10:37:33'),(2002,536,2,'2026-04-15 15:23:01'),(2004,546,1,'2026-04-15 14:01:42'),(2006,531,3,'2026-04-15 14:34:19'),(2008,516,1,'2026-04-15 11:31:46'),(2011,519,1,'2026-04-15 17:04:41'),(2015,543,2,'2026-04-16 16:58:18'),(2018,516,1,'2026-04-16 15:20:54'),(2019,545,1,'2026-04-16 18:30:41'),(2020,519,3,'2026-04-16 17:27:54'),(2023,543,1,'2026-04-16 14:02:50'),(2025,519,3,'2026-04-16 16:25:17'),(2027,546,2,'2026-04-16 11:22:48'),(2029,531,3,'2026-04-17 15:08:15'),(2030,541,1,'2026-04-17 14:23:09'),(2031,554,2,'2026-04-17 16:36:02'),(2032,536,3,'2026-04-17 12:40:58'),(2033,557,2,'2026-04-17 11:46:35'),(2035,545,1,'2026-04-17 12:12:41'),(2037,516,2,'2026-04-17 09:33:37'),(2038,542,2,'2026-04-17 10:31:22'),(2039,546,2,'2026-04-17 11:58:00'),(2041,531,3,'2026-04-17 13:42:15'),(2042,556,3,'2026-04-17 15:02:33'),(2043,528,2,'2026-04-17 09:46:39'),(2044,546,1,'2026-04-17 16:45:16'),(2045,545,2,'2026-04-18 10:23:42'),(2047,519,2,'2026-04-18 11:32:15'),(2050,546,3,'2026-04-18 17:17:12'),(2051,562,2,'2026-04-18 12:06:44'),(2052,516,3,'2026-04-18 16:01:59'),(2055,531,2,'2026-04-18 13:46:38'),(2056,531,1,'2026-04-18 14:04:00'),(2057,516,1,'2026-04-18 15:46:42'),(2060,561,2,'2026-04-19 15:14:09'),(2061,555,2,'2026-04-19 15:35:20'),(2063,556,3,'2026-04-19 09:33:44'),(2064,542,1,'2026-04-19 11:24:14'),(2065,562,2,'2026-04-19 15:15:34'),(2066,546,3,'2026-04-19 12:30:38'),(2069,557,1,'2026-04-19 16:30:44'),(2070,562,1,'2026-04-19 18:31:12'),(2076,528,1,'2026-04-19 10:31:54'),(2080,567,3,'2026-04-20 13:15:08'),(2081,519,3,'2026-04-20 13:53:24'),(2085,564,3,'2026-04-20 09:52:42'),(2087,567,2,'2026-04-20 12:17:31'),(2088,557,1,'2026-04-20 16:39:51'),(2089,556,3,'2026-04-20 13:43:04'),(2091,556,3,'2026-04-20 10:09:27'),(2093,555,1,'2026-04-20 13:12:54'),(2094,519,2,'2026-04-20 15:33:25'),(2096,531,1,'2026-04-20 12:28:18'),(2097,531,1,'2026-04-20 17:06:19'),(2098,561,1,'2026-04-20 14:17:12'),(2100,568,1,'2026-04-20 17:04:45'),(2101,568,1,'2026-04-21 18:10:09'),(2102,556,1,'2026-04-21 14:57:22'),(2103,562,2,'2026-04-21 13:06:40'),(2105,561,3,'2026-04-21 11:51:57'),(2108,541,2,'2026-04-21 14:07:06'),(2110,561,3,'2026-04-21 09:04:11'),(2111,564,1,'2026-04-21 15:25:14'),(2113,519,3,'2026-04-21 17:53:10'),(2115,556,3,'2026-04-21 11:33:54'),(2122,557,3,'2026-04-22 12:46:13'),(2123,546,2,'2026-04-22 13:06:08'),(2124,519,1,'2026-04-22 17:45:05'),(2125,546,2,'2026-04-22 16:41:45'),(2126,541,1,'2026-04-22 14:03:49'),(2129,557,2,'2026-04-22 17:31:04'),(2130,581,2,'2026-04-22 09:45:59'),(2131,582,2,'2026-04-22 09:01:43'),(2132,577,3,'2026-04-22 12:09:06'),(2134,556,3,'2026-04-22 16:41:00'),(2135,568,2,'2026-04-22 17:07:29'),(2136,577,1,'2026-04-22 18:14:57'),(2138,582,2,'2026-04-22 14:22:32'),(2141,582,3,'2026-04-22 10:25:36'),(2144,581,1,'2026-04-22 15:04:26'),(2145,577,3,'2026-04-23 13:02:03'),(2146,561,2,'2026-04-23 16:54:37'),(2148,579,1,'2026-04-23 16:03:36'),(2150,582,1,'2026-04-23 15:52:53'),(2151,541,1,'2026-04-23 15:28:27'),(2152,542,1,'2026-04-23 13:11:31'),(2155,571,3,'2026-04-23 11:23:25'),(2157,578,2,'2026-04-23 13:35:25'),(2158,582,2,'2026-04-23 16:02:47'),(2159,582,3,'2026-04-23 13:10:04'),(2161,580,1,'2026-04-23 09:54:03'),(2162,578,2,'2026-04-23 09:00:54'),(2166,556,1,'2026-04-24 16:40:35'),(2171,586,2,'2026-04-24 11:00:06'),(2173,578,2,'2026-04-24 13:42:14'),(2176,557,1,'2026-04-24 15:19:18'),(2180,592,1,'2026-04-25 14:59:16'),(2181,586,3,'2026-04-25 18:58:58'),(2184,579,2,'2026-04-25 11:16:47'),(2187,591,2,'2026-04-25 10:39:35'),(2190,591,1,'2026-04-25 13:36:28'),(2192,557,1,'2026-04-25 15:56:02'),(2193,561,1,'2026-04-25 18:18:25'),(2194,579,1,'2026-04-25 09:37:18'),(2195,519,1,'2026-04-25 15:12:28'),(2198,591,1,'2026-04-26 17:58:44'),(2199,564,3,'2026-04-26 09:17:55'),(2200,557,2,'2026-04-26 15:07:54'),(2201,577,2,'2026-04-26 09:48:10'),(2202,519,3,'2026-04-26 18:30:52'),(2205,594,3,'2026-04-26 13:19:29'),(2206,594,2,'2026-04-26 12:12:24'),(2207,581,1,'2026-04-26 15:50:07'),(2208,592,1,'2026-04-26 16:09:24'),(2209,571,1,'2026-04-26 16:10:02'),(2214,568,1,'2026-04-27 12:19:32'),(2215,557,1,'2026-04-27 16:41:32'),(2216,591,3,'2026-04-27 10:37:09'),(2217,591,1,'2026-04-27 11:57:32'),(2219,594,3,'2026-04-27 12:27:09'),(2221,599,2,'2026-04-27 13:03:28'),(2224,591,2,'2026-04-27 13:53:41'),(2227,561,3,'2026-04-27 10:13:09'),(2228,582,3,'2026-04-27 18:21:58'),(2229,599,1,'2026-04-27 12:01:45'),(2230,561,2,'2026-04-27 11:26:37'),(2231,519,1,'2026-04-27 09:22:33'),(2232,598,3,'2026-04-28 09:53:54'),(2233,519,3,'2026-04-28 12:53:26'),(2234,594,2,'2026-04-28 13:01:51'),(2235,586,1,'2026-04-28 12:50:13'),(2236,586,1,'2026-04-28 11:51:37'),(2237,594,2,'2026-04-28 09:47:04'),(2242,519,3,'2026-04-28 18:25:39'),(2244,601,1,'2026-04-28 13:52:15'),(2246,595,1,'2026-04-28 15:48:17'),(2247,591,1,'2026-04-28 09:08:12'),(2249,592,1,'2026-04-28 12:07:26'),(2251,586,2,'2026-04-28 16:43:42'),(2252,586,3,'2026-04-28 18:40:34'),(2253,582,2,'2026-04-28 18:09:47'),(2254,594,2,'2026-04-28 14:14:55'),(2255,519,2,'2026-04-28 13:03:22'),(2256,571,1,'2026-04-28 16:35:33'),(2257,595,2,'2026-04-28 15:13:58'),(2258,598,1,'2026-04-28 10:55:56'),(2260,594,2,'2026-04-29 10:35:17'),(2262,606,1,'2026-04-29 16:24:21'),(2264,564,1,'2026-04-29 15:27:33'),(2265,564,3,'2026-04-29 16:23:17'),(2267,607,1,'2026-04-29 15:11:10'),(2269,606,1,'2026-04-29 15:04:01'),(2270,606,1,'2026-04-29 10:28:11'),(2271,601,3,'2026-04-29 15:02:24'),(2272,592,2,'2026-04-29 16:47:34'),(2273,571,1,'2026-04-29 14:10:47'),(2275,592,3,'2026-04-29 16:28:47'),(2277,519,1,'2026-04-29 10:06:11'),(2279,582,1,'2026-04-29 17:40:19'),(2280,592,1,'2026-04-29 09:52:45'),(2281,609,1,'2026-04-29 09:48:27'),(2282,571,2,'2026-04-29 14:09:49'),(2283,519,2,'2026-04-29 14:04:27'),(2284,608,3,'2026-04-29 11:23:18'),(2286,609,3,'2026-04-29 11:27:03'),(2287,608,1,'2026-04-29 12:59:21'),(2292,614,3,'2026-04-30 14:43:27'),(2295,571,2,'2026-04-30 17:15:49'),(2297,571,2,'2026-04-30 18:51:25'),(2298,602,2,'2026-04-30 12:05:30'),(2299,586,1,'2026-04-30 14:17:27'),(2304,609,1,'2026-04-30 11:18:36'),(2306,609,2,'2026-05-01 14:29:38'),(2308,594,1,'2026-05-01 14:56:58'),(2310,628,2,'2026-05-01 15:36:33'),(2315,602,3,'2026-05-01 16:22:12'),(2318,626,3,'2026-05-01 14:52:41'),(2319,609,3,'2026-05-01 09:40:37'),(2320,627,1,'2026-05-01 14:26:00'),(2322,616,3,'2026-05-01 13:58:56'),(2325,628,1,'2026-05-02 17:24:40'),(2326,615,3,'2026-05-02 10:14:02'),(2327,626,1,'2026-05-02 18:37:47'),(2328,629,2,'2026-05-02 16:47:36'),(2330,608,3,'2026-05-02 17:41:41'),(2333,616,1,'2026-05-02 17:30:21'),(2335,626,3,'2026-05-02 18:45:44'),(2336,602,2,'2026-05-02 09:56:30'),(2339,602,2,'2026-05-02 15:11:29'),(2340,615,2,'2026-05-02 11:36:50'),(2341,616,2,'2026-05-02 15:22:30'),(2342,628,3,'2026-05-02 15:07:15'),(2348,615,3,'2026-05-03 14:06:11'),(2350,602,2,'2026-05-03 15:02:12'),(2352,586,1,'2026-05-03 09:01:13'),(2353,519,1,'2026-05-03 12:11:12'),(2357,571,1,'2026-05-03 11:05:23'),(2358,607,3,'2026-05-03 12:47:49'),(2360,625,1,'2026-05-03 13:51:30'),(2363,634,3,'2026-05-04 17:14:42'),(2364,636,3,'2026-05-04 16:49:58'),(2365,634,1,'2026-05-04 17:34:09'),(2368,608,2,'2026-05-04 11:21:13'),(2369,636,3,'2026-05-04 17:08:17'),(2370,636,2,'2026-05-04 18:54:14'),(2371,609,2,'2026-05-04 13:27:53'),(2372,625,1,'2026-05-04 15:02:37'),(2373,571,1,'2026-05-04 17:48:03'),(2374,614,2,'2026-05-04 18:28:47'),(2375,630,3,'2026-05-04 17:46:13'),(2379,626,3,'2026-05-04 18:46:49'),(2380,632,3,'2026-05-04 16:54:10'),(2383,519,3,'2026-05-04 09:34:50'),(2384,634,2,'2026-05-04 11:00:31'),(2385,602,2,'2026-05-04 16:36:14'),(2386,602,2,'2026-05-04 17:24:43'),(2387,626,1,'2026-05-05 16:08:43'),(2388,639,1,'2026-05-05 18:35:41'),(2389,608,3,'2026-05-05 12:00:03'),(2391,635,2,'2026-05-05 14:28:32'),(2392,632,3,'2026-05-05 11:36:31'),(2395,609,1,'2026-05-05 17:53:14'),(2396,614,1,'2026-05-05 12:06:01'),(2398,609,1,'2026-05-05 17:09:53'),(2400,637,1,'2026-05-05 15:37:06'),(2401,632,3,'2026-05-05 13:06:35'),(2402,519,2,'2026-05-05 13:20:51'),(2404,608,1,'2026-05-05 13:21:56'),(2405,614,2,'2026-05-05 09:53:35'),(2409,609,1,'2026-05-05 14:42:15'),(2410,602,2,'2026-05-05 18:12:28'),(2413,638,3,'2026-05-05 11:25:02'),(2417,571,2,'2026-05-06 17:38:11'),(2420,629,1,'2026-05-06 16:15:58'),(2421,629,3,'2026-05-06 15:41:25'),(2423,640,1,'2026-05-06 09:21:49'),(2424,636,2,'2026-05-06 12:18:29'),(2425,608,1,'2026-05-06 16:47:49'),(2426,519,1,'2026-05-06 09:07:41'),(2428,638,3,'2026-05-06 10:52:13'),(2430,626,2,'2026-05-06 15:05:41'),(2432,582,2,'2026-05-06 17:20:54'),(2433,582,2,'2026-05-06 16:20:49'),(2434,608,2,'2026-05-06 14:43:25'),(2435,632,2,'2026-05-06 09:25:35'),(2436,638,3,'2026-05-06 16:10:30'),(2437,639,2,'2026-05-06 09:48:21'),(2439,602,1,'2026-05-06 17:31:09'),(2440,650,2,'2026-05-07 14:46:59'),(2441,627,1,'2026-05-07 17:02:22'),(2442,640,3,'2026-05-07 17:07:23'),(2444,649,2,'2026-05-07 12:10:51'),(2445,650,3,'2026-05-07 16:45:24'),(2446,627,1,'2026-05-07 15:26:09'),(2449,647,1,'2026-05-07 12:51:44'),(2450,608,3,'2026-05-07 17:18:09'),(2452,602,3,'2026-05-07 16:01:59'),(2454,519,2,'2026-05-07 16:01:55'),(2455,649,1,'2026-05-07 09:23:26'),(2458,602,2,'2026-05-07 15:55:56'),(2459,630,2,'2026-05-07 09:35:49'),(2463,630,2,'2026-05-07 15:21:05'),(2464,627,1,'2026-05-07 15:13:42'),(2467,629,2,'2026-05-08 09:30:55'),(2468,639,1,'2026-05-08 13:24:37'),(2469,650,3,'2026-05-08 09:27:08'),(2470,630,1,'2026-05-08 16:25:10'),(2471,650,1,'2026-05-08 14:49:49'),(2472,655,2,'2026-05-08 10:43:43'),(2473,629,3,'2026-05-08 14:55:23'),(2474,652,1,'2026-05-08 18:11:26'),(2475,637,2,'2026-05-08 17:25:12'),(2477,654,3,'2026-05-08 16:02:33'),(2478,602,1,'2026-05-08 17:21:56'),(2479,654,2,'2026-05-08 16:14:43'),(2480,650,2,'2026-05-08 11:27:03'),(2481,650,3,'2026-05-08 11:38:11'),(2483,654,1,'2026-05-08 09:48:25'),(2484,652,3,'2026-05-08 18:10:45'),(2486,629,1,'2026-05-08 11:55:27'),(2487,655,3,'2026-05-08 14:54:28'),(2488,660,2,'2026-05-09 13:00:35'),(2493,626,2,'2026-05-09 09:38:33'),(2496,649,3,'2026-05-09 12:15:14'),(2498,661,2,'2026-05-09 12:25:29'),(2499,650,3,'2026-05-09 13:38:42'),(2500,629,3,'2026-05-09 18:33:37'),(2501,661,3,'2026-05-09 09:52:56'),(2503,602,2,'2026-05-09 15:27:50'),(2504,662,3,'2026-05-09 09:35:08'),(2505,660,3,'2026-05-09 13:29:40'),(2506,608,2,'2026-05-09 12:53:30'),(2507,664,2,'2026-05-10 18:32:54'),(2508,636,1,'2026-05-10 17:31:37'),(2509,660,1,'2026-05-10 12:23:30'),(2510,660,1,'2026-05-10 17:26:04'),(2511,629,3,'2026-05-10 15:53:18'),(2512,654,1,'2026-05-10 17:51:57'),(2514,655,3,'2026-05-10 16:46:14'),(2516,653,1,'2026-05-10 09:52:45'),(2517,661,3,'2026-05-10 16:24:39'),(2519,665,2,'2026-05-10 12:34:25'),(2521,602,1,'2026-05-10 09:56:59'),(2522,664,2,'2026-05-10 18:44:57'),(2523,602,2,'2026-05-10 15:47:45'),(2524,649,2,'2026-05-10 12:17:25'),(2525,666,3,'2026-05-10 13:26:57'),(2526,652,3,'2026-05-10 14:50:25'),(2527,666,3,'2026-05-10 13:12:50'),(2529,654,3,'2026-05-10 12:34:22'),(2530,665,3,'2026-05-10 15:21:54'),(2532,672,1,'2026-05-11 13:41:23'),(2534,654,1,'2026-05-11 17:45:28'),(2535,664,1,'2026-05-11 10:25:02'),(2537,664,3,'2026-05-11 13:15:42'),(2538,630,1,'2026-05-11 13:56:24'),(2540,639,2,'2026-05-11 16:59:14'),(2541,652,3,'2026-05-11 14:17:54'),(2542,670,2,'2026-05-11 12:22:56'),(2547,670,1,'2026-05-12 16:07:24'),(2548,650,3,'2026-05-12 10:45:33'),(2549,650,2,'2026-05-12 09:43:14'),(2554,602,2,'2026-05-12 17:15:33'),(2555,665,2,'2026-05-12 10:42:27'),(2556,676,2,'2026-05-12 16:49:26'),(2557,677,1,'2026-05-12 11:56:43'),(2558,672,1,'2026-05-12 11:46:52'),(2561,674,3,'2026-05-13 10:27:46'),(2562,679,2,'2026-05-13 13:21:09'),(2563,636,2,'2026-05-13 09:44:56'),(2564,676,2,'2026-05-13 09:58:06'),(2565,665,1,'2026-05-13 13:21:48'),(2566,676,2,'2026-05-13 11:05:00'),(2567,676,2,'2026-05-13 12:49:51'),(2569,671,2,'2026-05-13 15:09:15'),(2570,671,2,'2026-05-13 13:15:26'),(2571,652,3,'2026-05-13 09:50:22'),(2573,679,2,'2026-05-13 14:20:09'),(2576,636,2,'2026-05-13 10:56:51'),(2577,655,1,'2026-05-13 15:25:05'),(2578,602,2,'2026-05-13 15:21:39'),(2582,654,2,'2026-05-14 09:33:02'),(2583,636,1,'2026-05-14 17:20:19'),(2584,652,2,'2026-05-14 13:30:00'),(2585,666,3,'2026-05-14 14:45:15'),(2586,660,1,'2026-05-14 09:44:04'),(2588,671,1,'2026-05-14 11:46:57'),(2592,655,1,'2026-05-14 16:15:00'),(2593,671,1,'2026-05-14 12:18:29'),(2594,664,3,'2026-05-14 15:29:42'),(2595,675,3,'2026-05-15 12:22:15'),(2597,679,1,'2026-05-15 15:38:06'),(2599,602,1,'2026-05-15 16:26:27'),(2604,654,2,'2026-05-15 10:02:51'),(2605,654,3,'2026-05-15 10:38:40'),(2609,685,1,'2026-05-15 10:14:14'),(2612,677,2,'2026-05-15 10:58:22'),(2613,664,1,'2026-05-15 14:32:47'),(2614,602,1,'2026-05-15 15:24:48'),(2615,655,3,'2026-05-15 15:16:48'),(2616,676,2,'2026-05-15 14:36:02'),(2618,676,3,'2026-05-15 18:00:52'),(2620,676,2,'2026-05-15 18:16:08'),(2621,676,2,'2026-05-15 11:41:04'),(2623,687,2,'2026-05-16 12:18:02'),(2624,698,1,'2026-05-16 10:41:59'),(2626,685,3,'2026-05-16 11:27:55'),(2627,654,1,'2026-05-16 17:46:56'),(2629,686,3,'2026-05-16 15:24:49'),(2631,685,2,'2026-05-16 13:23:05'),(2633,691,2,'2026-05-16 17:37:38'),(2634,697,1,'2026-05-16 12:11:54'),(2635,695,3,'2026-05-16 16:17:55'),(2637,666,1,'2026-05-16 15:08:54'),(2638,602,2,'2026-05-16 14:51:01'),(2639,675,1,'2026-05-16 09:04:53'),(2642,690,3,'2026-05-16 09:48:22'),(2644,685,1,'2026-05-16 18:04:07'),(2645,677,1,'2026-05-16 09:06:36'),(2646,664,1,'2026-05-16 15:35:08'),(2647,664,2,'2026-05-16 09:37:01'),(2648,655,1,'2026-05-16 15:24:57'),(2650,691,1,'2026-05-16 15:15:28'),(2652,664,2,'2026-05-17 18:03:44'),(2653,689,2,'2026-05-17 11:11:34'),(2655,697,1,'2026-05-17 18:15:13'),(2656,695,1,'2026-05-17 13:54:11'),(2657,654,3,'2026-05-17 17:18:23'),(2659,677,3,'2026-05-17 16:13:53'),(2660,690,2,'2026-05-17 12:26:38'),(2661,690,1,'2026-05-17 10:35:59'),(2663,687,1,'2026-05-17 14:16:11'),(2664,702,3,'2026-05-17 16:09:46'),(2665,690,2,'2026-05-17 12:15:34'),(2667,689,2,'2026-05-17 15:58:41'),(2668,654,3,'2026-05-17 09:25:46'),(2669,702,1,'2026-05-17 12:59:04'),(2670,702,2,'2026-05-17 14:55:17'),(2672,695,2,'2026-05-17 10:17:51'),(2675,701,1,'2026-05-17 16:22:58'),(2677,677,3,'2026-05-18 09:07:06'),(2678,701,2,'2026-05-18 09:05:17'),(2680,695,3,'2026-05-18 17:01:28'),(2681,696,2,'2026-05-18 12:12:16'),(2682,696,1,'2026-05-18 18:51:26'),(2683,686,1,'2026-05-18 10:42:13'),(2684,705,2,'2026-05-18 17:11:01'),(2686,677,2,'2026-05-18 13:19:05'),(2687,689,1,'2026-05-18 17:36:34'),(2688,602,3,'2026-05-18 09:54:43'),(2691,687,3,'2026-05-18 13:18:44'),(2692,697,2,'2026-05-18 11:59:43'),(2693,602,2,'2026-05-18 15:10:55'),(2697,687,2,'2026-05-18 17:32:48'),(2698,695,1,'2026-05-18 15:16:36'),(2699,654,3,'2026-05-18 10:09:15'),(2700,654,1,'2026-05-19 09:19:11'),(2701,677,2,'2026-05-19 17:47:31'),(2702,687,3,'2026-05-19 10:17:12'),(2706,712,1,'2026-05-19 15:55:56'),(2707,700,3,'2026-05-19 13:50:05'),(2708,687,1,'2026-05-19 12:13:05'),(2709,708,1,'2026-05-19 10:35:41'),(2710,695,3,'2026-05-19 11:02:41'),(2711,705,1,'2026-05-19 11:50:47'),(2713,711,3,'2026-05-19 14:37:49'),(2717,654,3,'2026-05-19 18:06:38'),(2719,712,2,'2026-05-19 10:39:50'),(2720,712,2,'2026-05-19 18:13:26'),(2721,695,1,'2026-05-19 14:33:52'),(2722,702,3,'2026-05-19 11:57:44'),(2723,687,2,'2026-05-19 16:38:03'),(2724,712,1,'2026-05-20 10:58:21'),(2725,719,1,'2026-05-20 14:12:52'),(2726,710,1,'2026-05-20 10:09:23'),(2727,716,1,'2026-05-20 11:20:09'),(2728,654,2,'2026-05-20 15:01:58'),(2729,677,2,'2026-05-20 18:02:05'),(2731,712,1,'2026-05-20 17:17:40'),(2732,654,3,'2026-05-20 12:57:55'),(2735,708,3,'2026-05-20 11:33:32'),(2736,702,3,'2026-05-20 16:44:47'),(2737,654,2,'2026-05-20 18:51:51'),(2738,716,2,'2026-05-20 17:46:31'),(2740,654,3,'2026-05-20 11:17:50'),(2741,702,2,'2026-05-20 17:38:36'),(2743,677,3,'2026-05-20 12:37:21'),(2744,696,1,'2026-05-20 12:54:22'),(2746,710,1,'2026-05-21 17:43:30'),(2747,654,1,'2026-05-21 18:35:20'),(2748,721,3,'2026-05-21 14:07:52'),(2749,728,1,'2026-05-21 17:36:53'),(2753,700,2,'2026-05-21 18:17:59'),(2755,702,2,'2026-05-21 16:41:21'),(2756,722,3,'2026-05-21 14:35:37'),(2758,695,2,'2026-05-21 09:04:53'),(2759,722,3,'2026-05-21 16:42:16'),(2760,710,1,'2026-05-21 12:41:13'),(2762,689,1,'2026-05-21 14:12:53'),(2763,711,1,'2026-05-21 16:39:57'),(2764,677,2,'2026-05-21 14:44:05'),(2766,721,1,'2026-05-21 10:57:41'),(2767,717,2,'2026-05-21 13:29:58'),(2768,721,1,'2026-05-21 12:23:12'),(2769,718,2,'2026-05-21 16:53:50'),(2771,711,1,'2026-05-22 10:33:25'),(2780,696,2,'2026-05-22 17:36:31'),(2781,717,2,'2026-05-22 11:53:04'),(2783,705,1,'2026-05-22 10:46:19'),(2784,717,2,'2026-05-22 09:02:52'),(2786,718,3,'2026-05-22 11:34:26'),(2787,695,2,'2026-05-23 13:13:45'),(2791,695,2,'2026-05-23 18:19:34'),(2792,717,1,'2026-05-23 10:02:04'),(2793,734,2,'2026-05-23 16:14:59'),(2794,728,2,'2026-05-23 10:02:12'),(2796,716,1,'2026-05-23 12:03:12'),(2798,712,2,'2026-05-23 17:20:25'),(2800,711,1,'2026-05-23 17:56:14'),(2801,722,3,'2026-05-23 11:10:04'),(2802,732,1,'2026-05-23 17:58:36'),(2804,722,2,'2026-05-23 09:42:34'),(2809,711,3,'2026-05-23 10:53:28'),(2810,717,2,'2026-05-24 16:11:12'),(2812,738,2,'2026-05-24 11:53:20'),(2813,712,2,'2026-05-24 17:11:15'),(2814,731,3,'2026-05-24 14:32:51'),(2816,737,3,'2026-05-24 18:13:48'),(2817,718,1,'2026-05-24 18:01:35'),(2819,711,1,'2026-05-24 16:06:45'),(2822,730,2,'2026-05-25 12:34:09'),(2823,734,2,'2026-05-25 11:00:40'),(2824,731,2,'2026-05-25 15:27:03'),(2825,735,3,'2026-05-25 18:53:39'),(2827,735,1,'2026-05-25 17:20:23'),(2829,702,1,'2026-05-25 13:21:00'),(2830,734,2,'2026-05-25 09:20:45'),(2831,741,1,'2026-05-25 17:31:55'),(2832,732,3,'2026-05-25 14:56:16'),(2833,740,1,'2026-05-25 10:01:33'),(2834,728,1,'2026-05-25 14:06:15'),(2835,739,2,'2026-05-25 16:27:43'),(2836,732,1,'2026-05-25 09:34:49'),(2838,728,3,'2026-05-25 18:55:55'),(2839,730,2,'2026-05-25 13:57:15'),(2840,742,1,'2026-05-26 18:20:28'),(2841,732,1,'2026-05-26 15:34:11'),(2842,696,3,'2026-05-26 17:14:10'),(2844,731,3,'2026-05-26 14:11:16'),(2845,730,1,'2026-05-26 12:07:03'),(2846,742,3,'2026-05-26 15:47:57'),(2847,740,2,'2026-05-26 11:11:30'),(2848,730,1,'2026-05-26 11:31:15'),(2849,718,3,'2026-05-26 12:25:01'),(2852,696,1,'2026-05-26 11:07:50'),(2853,711,3,'2026-05-26 13:37:21'),(2854,718,1,'2026-05-26 15:45:58'),(2856,712,1,'2026-05-26 13:03:53'),(2858,737,1,'2026-05-26 14:25:45'),(2859,736,3,'2026-05-26 11:55:46'),(2860,734,1,'2026-05-26 10:25:40'),(2862,722,1,'2026-05-26 15:28:02'),(2863,741,3,'2026-05-26 18:48:37'),(2864,722,3,'2026-05-26 10:37:23'),(2865,711,2,'2026-05-27 18:00:45'),(2866,712,2,'2026-05-27 18:25:15'),(2868,752,3,'2026-05-27 17:03:12'),(2870,711,1,'2026-05-27 09:34:36'),(2871,749,3,'2026-05-27 09:21:53'),(2873,748,3,'2026-05-27 18:25:10'),(2874,711,3,'2026-05-27 10:08:45'),(2875,736,3,'2026-05-27 13:27:43'),(2877,711,1,'2026-05-27 15:15:23'),(2878,751,1,'2026-05-27 13:11:36'),(2880,734,2,'2026-05-27 18:23:15'),(2881,749,2,'2026-05-27 15:21:38'),(2882,755,1,'2026-05-28 16:24:47'),(2883,734,3,'2026-05-28 17:53:37'),(2885,753,3,'2026-05-28 11:11:11'),(2886,712,1,'2026-05-28 11:04:11'),(2887,712,1,'2026-05-28 11:03:17'),(2888,753,1,'2026-05-28 17:09:57'),(2890,753,3,'2026-05-28 10:32:31'),(2891,755,1,'2026-05-28 16:32:27'),(2892,751,3,'2026-05-28 14:55:19'),(2894,712,1,'2026-05-28 14:02:00'),(2895,751,2,'2026-05-28 10:45:49'),(2896,755,3,'2026-05-28 10:38:02'),(2897,756,1,'2026-05-28 09:41:31'),(2898,744,2,'2026-05-28 12:02:56'),(2899,736,3,'2026-05-28 09:57:29'),(2900,731,3,'2026-05-28 09:22:05'),(2901,731,2,'2026-05-28 15:14:27'),(2902,748,1,'2026-05-28 14:49:03'),(2903,728,3,'2026-05-28 09:09:04'),(2904,756,2,'2026-05-28 18:56:54'),(2905,748,1,'2026-05-28 11:25:51'),(2906,712,2,'2026-05-28 14:15:47'),(2907,742,3,'2026-05-28 14:18:13'),(2908,742,2,'2026-05-28 13:47:38'),(2909,731,1,'2026-05-28 15:45:16'),(2911,761,1,'2026-05-29 09:22:49'),(2912,755,1,'2026-05-29 17:28:28'),(2913,712,3,'2026-05-29 14:32:18'),(2916,751,2,'2026-05-29 13:08:45'),(2917,753,1,'2026-05-29 11:49:23'),(2918,758,2,'2026-05-29 11:44:55'),(2921,761,1,'2026-05-29 10:38:38'),(2922,750,2,'2026-05-29 10:16:16'),(2925,751,1,'2026-05-29 11:31:56'),(2926,761,2,'2026-05-30 09:31:29'),(2927,734,1,'2026-05-30 16:13:02'),(2928,712,3,'2026-05-30 11:31:51'),(2929,744,2,'2026-05-30 10:57:14'),(2930,734,3,'2026-05-30 10:41:32'),(2931,750,3,'2026-05-30 16:43:17'),(2932,745,1,'2026-05-30 15:46:28'),(2933,744,1,'2026-05-30 18:57:50'),(2935,744,2,'2026-05-30 18:28:51'),(2936,751,1,'2026-05-30 11:57:55'),(2937,744,1,'2026-05-30 17:39:10'),(2938,739,1,'2026-05-30 16:28:49'),(2939,748,1,'2026-05-30 13:58:11'),(2940,759,3,'2026-05-30 09:14:01'),(2941,731,1,'2026-05-30 15:04:47'),(2942,757,2,'2026-05-31 09:26:22'),(2943,759,3,'2026-05-31 09:29:03'),(2945,734,2,'2026-05-31 15:38:21'),(2946,758,2,'2026-05-31 15:23:56'),(2949,758,1,'2026-05-31 13:54:44'),(2950,728,3,'2026-05-31 18:47:37'),(2951,767,3,'2026-05-31 15:06:28'),(2952,742,1,'2026-05-31 10:23:49'),(2953,766,2,'2026-05-31 13:14:14'),(2955,750,3,'2026-05-31 12:43:55'),(2956,753,2,'2026-05-31 11:08:14'),(2957,762,2,'2026-05-31 18:49:30'),(2959,763,2,'2026-05-31 18:53:45'),(2960,758,1,'2026-05-31 16:56:43'),(2961,766,3,'2026-05-31 16:55:52'),(2962,753,1,'2026-06-01 10:42:29'),(2963,757,1,'2026-06-01 12:59:50'),(2964,759,1,'2026-06-01 12:58:52'),(2965,762,3,'2026-06-01 17:42:55'),(2967,763,1,'2026-06-01 16:40:41'),(2968,774,3,'2026-06-01 13:42:45'),(2969,768,3,'2026-06-01 09:07:38'),(2970,764,3,'2026-06-01 17:47:21'),(2971,750,1,'2026-06-01 15:59:37'),(2972,745,1,'2026-06-01 16:43:19'),(2973,772,3,'2026-06-01 10:20:19'),(2974,772,1,'2026-06-01 17:03:18'),(2975,753,3,'2026-06-01 12:04:50'),(2976,739,1,'2026-06-01 10:21:47'),(2978,772,2,'2026-06-02 10:11:34'),(2979,780,2,'2026-06-02 10:16:36'),(2980,760,1,'2026-06-02 13:29:52'),(2981,763,1,'2026-06-02 10:15:49'),(2982,779,1,'2026-06-02 10:27:56'),(2983,757,1,'2026-06-02 17:30:25'),(2984,731,1,'2026-06-02 16:51:01'),(2986,762,1,'2026-06-02 15:58:51'),(2987,769,1,'2026-06-02 12:07:42'),(2988,772,2,'2026-06-02 10:21:14'),(2990,769,3,'2026-06-02 09:32:16'),(2991,771,2,'2026-06-02 12:41:08'),(2992,767,1,'2026-06-02 15:28:07'),(2993,778,3,'2026-06-02 17:48:43'),(2994,762,3,'2026-06-02 15:28:41'),(2995,712,3,'2026-06-02 14:02:13'),(2996,757,1,'2026-06-02 09:27:23'),(2997,728,1,'2026-06-02 09:38:12'),(2998,772,1,'2026-06-02 12:19:56'),(2999,778,3,'2026-06-02 18:15:21'),(3000,779,3,'2026-06-02 15:11:33'),(3001,775,3,'2026-06-02 18:18:03'),(3002,764,1,'2026-06-02 16:06:25'),(3003,764,3,'2026-06-02 10:31:27'),(3004,728,2,'2026-06-02 10:18:37'),(3005,728,1,'2026-06-02 17:45:26'),(3006,778,2,'2026-06-03 15:30:17'),(3007,728,2,'2026-06-03 16:26:31'),(3008,769,1,'2026-06-03 12:25:00'),(3009,712,3,'2026-06-03 12:53:44'),(3010,784,2,'2026-06-03 14:20:55'),(3011,781,3,'2026-06-03 09:49:54'),(3012,753,3,'2026-06-03 14:23:21'),(3013,762,3,'2026-06-03 16:06:42'),(3014,781,2,'2026-06-03 18:14:12'),(3015,775,1,'2026-06-03 10:03:47'),(3016,764,1,'2026-06-03 16:15:04'),(3017,774,1,'2026-06-03 15:42:15'),(3018,766,1,'2026-06-03 15:56:32'),(3019,758,1,'2026-06-03 17:58:57'),(3020,731,2,'2026-06-03 10:45:40'),(3021,779,2,'2026-06-03 10:59:06'),(3022,745,2,'2026-06-03 09:40:20'),(3024,776,3,'2026-06-03 13:29:36'),(3025,779,2,'2026-06-03 12:20:29'),(3026,785,3,'2026-06-03 12:20:40'),(3028,745,2,'2026-06-03 18:50:40'),(3029,775,1,'2026-06-03 10:49:49'),(3030,784,1,'2026-06-03 16:31:00'),(3031,782,2,'2026-06-03 09:24:49'),(3032,782,2,'2026-06-03 14:39:59'),(3033,745,1,'2026-06-03 10:03:28'),(3034,787,1,'2026-06-04 14:01:31'),(3035,753,1,'2026-06-04 12:53:16'),(3036,791,1,'2026-06-04 11:43:37'),(3037,728,1,'2026-06-04 17:54:37'),(3038,795,3,'2026-06-04 12:55:23'),(3040,786,3,'2026-06-04 18:00:17'),(3041,772,2,'2026-06-04 10:39:08'),(3042,785,2,'2026-06-04 12:17:28'),(3043,776,2,'2026-06-04 13:39:42'),(3044,783,1,'2026-06-04 11:34:40'),(3045,792,2,'2026-06-04 18:33:23'),(3046,753,3,'2026-06-04 17:31:15'),(3047,762,2,'2026-06-04 09:01:45'),(3048,728,1,'2026-06-04 11:44:36'),(3049,784,1,'2026-06-04 11:36:40'),(3050,792,2,'2026-06-04 14:26:47'),(3051,782,1,'2026-06-04 17:08:45'),(3052,788,1,'2026-06-04 15:42:55'),(3053,790,2,'2026-06-04 15:48:47'),(3055,785,3,'2026-06-04 10:32:34'),(3056,783,2,'2026-06-04 11:05:07'),(3057,793,2,'2026-06-04 16:55:09'),(3058,790,2,'2026-06-04 15:47:28'),(3059,798,3,'2026-06-05 09:58:04'),(3060,773,1,'2026-06-05 09:45:10'),(3061,793,1,'2026-06-05 09:32:35'),(3062,762,1,'2026-06-05 12:37:42'),(3063,798,2,'2026-06-05 13:58:38'),(3065,799,2,'2026-06-05 10:33:47'),(3066,791,2,'2026-06-05 14:33:22'),(3067,791,1,'2026-06-05 16:02:52'),(3068,712,1,'2026-06-05 13:34:43'),(3069,797,1,'2026-06-05 16:15:09'),(3070,793,2,'2026-06-05 14:08:40'),(3071,795,1,'2026-06-05 14:14:13'),(3072,712,1,'2026-06-05 16:24:39'),(3073,773,2,'2026-06-05 13:09:20'),(3074,798,1,'2026-06-05 18:06:11'),(3075,762,3,'2026-06-05 14:02:21'),(3076,793,2,'2026-06-05 11:07:39'),(3077,792,2,'2026-06-05 13:04:48'),(3078,753,1,'2026-06-06 16:12:05'),(3079,797,1,'2026-06-06 17:45:09'),(3080,780,3,'2026-06-06 11:01:11'),(3081,802,1,'2026-06-06 10:58:18'),(3082,803,3,'2026-06-06 17:40:47'),(3083,790,1,'2026-06-06 13:58:06'),(3084,745,2,'2026-06-06 12:24:46'),(3085,794,2,'2026-06-06 14:36:38'),(3086,795,1,'2026-06-06 15:17:35'),(3087,786,1,'2026-06-06 17:57:00'),(3088,764,3,'2026-06-06 18:36:05'),(3089,800,3,'2026-06-06 14:26:07'),(3090,786,2,'2026-06-06 11:20:53'),(3091,762,1,'2026-06-06 11:00:23'),(3092,785,3,'2026-06-06 10:29:12'),(3093,780,2,'2026-06-06 09:37:20'),(3094,797,1,'2026-06-06 17:23:34'),(3095,771,1,'2026-06-06 09:44:07'),(3096,798,3,'2026-06-06 17:57:41'),(3097,787,3,'2026-06-06 11:39:41'),(3098,790,1,'2026-06-07 09:00:41'),(3099,763,1,'2026-06-07 09:32:02'),(3100,795,2,'2026-06-07 16:01:19'),(3101,802,2,'2026-06-07 14:20:02'),(3102,795,3,'2026-06-07 14:54:40'),(3103,762,2,'2026-06-07 09:23:35'),(3104,764,2,'2026-06-07 14:20:24'),(3105,786,2,'2026-06-07 10:39:08'),(3106,758,1,'2026-06-07 16:28:59'),(3107,789,3,'2026-06-07 12:20:11'),(3108,764,1,'2026-06-07 12:37:56'),(3109,785,2,'2026-06-07 18:57:45'),(3110,794,3,'2026-06-07 15:00:44'),(3111,789,2,'2026-06-07 10:31:46'),(3112,768,1,'2026-06-07 13:26:07'),(3113,802,1,'2026-06-08 11:50:43'),(3114,795,3,'2026-06-08 12:01:47'),(3115,786,1,'2026-06-08 15:52:42'),(3116,728,1,'2026-06-08 16:12:43'),(3117,804,2,'2026-06-08 18:33:20'),(3118,785,1,'2026-06-08 15:30:49'),(3119,801,2,'2026-06-08 12:52:25'),(3120,801,1,'2026-06-08 11:25:02'),(3121,763,3,'2026-06-08 13:22:40'),(3122,762,2,'2026-06-08 14:27:57'),(3123,801,1,'2026-06-08 15:17:00'),(3124,804,1,'2026-06-08 16:54:20'),(3125,797,1,'2026-06-09 10:23:38'),(3126,780,2,'2026-06-09 12:18:44'),(3127,712,1,'2026-06-09 10:09:12'),(3128,812,2,'2026-06-09 15:59:59'),(3129,796,2,'2026-06-09 14:10:48'),(3130,812,3,'2026-06-09 09:24:42'),(3131,763,3,'2026-06-09 18:45:46'),(3132,812,2,'2026-06-09 14:29:38'),(3133,788,1,'2026-06-09 10:33:25'),(3134,791,2,'2026-06-09 11:13:25'),(3135,805,3,'2026-06-09 15:39:03'),(3136,795,1,'2026-06-09 16:14:21'),(3137,758,2,'2026-06-09 12:51:13'),(3138,810,1,'2026-06-09 16:11:42'),(3139,768,1,'2026-06-09 14:04:31'),(3140,762,2,'2026-06-09 14:33:52'),(3141,812,1,'2026-06-09 11:37:01'),(3142,806,3,'2026-06-09 17:56:12'),(3143,797,2,'2026-06-09 17:34:38'),(3144,806,1,'2026-06-09 11:17:04'),(3145,712,1,'2026-06-09 14:22:57'),(3146,794,2,'2026-06-09 14:45:43'),(3147,762,2,'2026-06-09 22:31:46');
/*!40000 ALTER TABLE `historicolote` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `insumo`
--

DROP TABLE IF EXISTS `insumo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insumo` (
  `idInsumo` int NOT NULL AUTO_INCREMENT,
  `fkCategoria` int DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `qtdMinima` int DEFAULT NULL,
  `rotatividade` bit(1) DEFAULT NULL,
  `ativo` bit(1) DEFAULT NULL,
  PRIMARY KEY (`idInsumo`),
  KEY `fk_insumo_categoria` (`fkCategoria`),
  CONSTRAINT `fk_insumo_categoria` FOREIGN KEY (`fkCategoria`) REFERENCES `categoria` (`idCategoria`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `insumo`
--

LOCK TABLES `insumo` WRITE;
/*!40000 ALTER TABLE `insumo` DISABLE KEYS */;
INSERT INTO `insumo` VALUES (1,1,'Peito de Frango',6,_binary '',_binary ''),(2,1,'Carne Bovina Moida',5,_binary '',_binary ''),(3,1,'Carne Suina',4,_binary '',_binary ''),(4,2,'File de Tilapia',4,_binary '',_binary ''),(5,2,'Sardinha',6,_binary '\0',_binary ''),(6,3,'Cebola',8,_binary '',_binary ''),(7,3,'Alho',3,_binary '',_binary ''),(8,3,'Tomate',8,_binary '',_binary ''),(9,4,'Leite Integral',12,_binary '',_binary ''),(10,4,'Queijo Mussarela',4,_binary '',_binary ''),(11,4,'Manteiga',3,_binary '',_binary ''),(12,5,'Bacon',3,_binary '',_binary ''),(13,5,'Linguica Toscana',4,_binary '',_binary ''),(14,5,'Presunto',3,_binary '',_binary ''),(15,6,'Arroz Branco',10,_binary '\0',_binary ''),(16,6,'Feijao Carioca',8,_binary '\0',_binary ''),(17,6,'Farinha de Trigo',6,_binary '\0',_binary ''),(18,6,'Macarrao Espaguete',8,_binary '\0',_binary ''),(19,7,'Sal Refinado',3,_binary '\0',_binary ''),(20,7,'Pimenta do Reino',2,_binary '\0',_binary ''),(21,7,'Molho de Tomate',10,_binary '',_binary ''),(22,7,'Vinagre',2,_binary '\0',_binary ''),(23,8,'Oleo de Soja',4,_binary '\0',_binary ''),(24,8,'Azeite',2,_binary '\0',_binary ''),(25,9,'Refrigerante',18,_binary '\0',_binary ''),(26,9,'Agua Mineral',36,_binary '\0',_binary ''),(27,9,'Suco de Laranja',12,_binary '',_binary '');
/*!40000 ALTER TABLE `insumo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lote`
--

DROP TABLE IF EXISTS `lote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lote` (
  `idLote` int NOT NULL AUTO_INCREMENT,
  `dataValidade` date DEFAULT NULL,
  `precoUnit` double DEFAULT NULL,
  `unidadeMedida` varchar(255) DEFAULT NULL,
  `quantidadeMedida` double DEFAULT NULL,
  `quantidadeOriginal` int DEFAULT NULL,
  `quantidadeAtual` int DEFAULT NULL,
  `dataEntrada` date DEFAULT NULL,
  `ativo` bit(1) DEFAULT NULL,
  `fkMarca` int DEFAULT NULL,
  `fkUsuario` int DEFAULT NULL,
  PRIMARY KEY (`idLote`),
  KEY `fk_lote_marca` (`fkMarca`),
  KEY `fk_lote_usuario` (`fkUsuario`),
  CONSTRAINT `fk_lote_marca` FOREIGN KEY (`fkMarca`) REFERENCES `marca` (`idMarca`),
  CONSTRAINT `fk_lote_usuario` FOREIGN KEY (`fkUsuario`) REFERENCES `usuario` (`idUsuario`)
) ENGINE=InnoDB AUTO_INCREMENT=819 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lote`
--

LOCK TABLES `lote` WRITE;
/*!40000 ALTER TABLE `lote` DISABLE KEYS */;
INSERT INTO `lote` VALUES (1,'2026-06-14',15.9,'kg',1,12,0,'2026-06-09',_binary '',1,1),(2,'2026-06-15',32.9,'kg',1,10,0,'2026-06-09',_binary '',3,2),(3,'2026-06-16',28.9,'kg',1,8,0,'2026-06-09',_binary '',5,1),(4,'2026-06-13',34.9,'kg',1,6,0,'2026-06-09',_binary '',7,3),(5,'2026-06-19',10.9,'un',1,24,0,'2026-06-09',_binary '',9,3),(6,'2026-06-21',6.5,'kg',1,10,0,'2026-06-09',_binary '',11,2),(7,'2026-06-29',22,'kg',1,3,0,'2026-06-09',_binary '',13,2),(8,'2026-06-16',8.9,'kg',1,8,0,'2026-06-09',_binary '',15,2),(9,'2026-06-17',5.49,'L',1,18,0,'2026-06-09',_binary '',17,1),(10,'2026-06-21',39.9,'kg',1,6,0,'2026-06-09',_binary '',19,1),(11,'2026-07-04',17.9,'g',200,12,0,'2026-06-09',_binary '',21,1),(12,'2026-06-24',29.9,'kg',1,5,0,'2026-06-09',_binary '',23,1),(13,'2026-06-21',19.9,'kg',1,6,0,'2026-06-09',_binary '',25,2),(14,'2026-06-19',18.5,'kg',1,4,0,'2026-06-09',_binary '',27,2),(15,'2027-04-09',27.9,'kg',5,4,0,'2026-06-09',_binary '',29,3),(16,'2027-03-09',8.9,'kg',1,8,0,'2026-06-09',_binary '',31,3),(17,'2027-02-09',6.9,'kg',1,6,0,'2026-06-09',_binary '',33,3),(18,'2027-03-09',4.9,'un',500,10,0,'2026-06-09',_binary '',35,3),(19,'2027-12-09',3.2,'kg',1,2,0,'2026-06-09',_binary '',37,2),(20,'2028-06-09',6.5,'g',50,6,0,'2026-06-09',_binary '',39,2),(21,'2027-12-09',4.9,'ml',750,4,0,'2026-06-09',_binary '',43,2),(22,'2027-08-09',7.9,'ml',900,6,0,'2026-06-09',_binary '',45,1),(23,'2026-10-09',8.9,'L',2,24,0,'2026-06-09',_binary '',49,3),(24,'2026-09-09',7.9,'L',1,18,0,'2026-06-09',_binary '',53,3),(25,'2026-06-11',15.5,'kg',1,8,0,'2026-06-07',_binary '',2,2),(26,'2026-06-12',33.9,'kg',1,6,0,'2026-06-08',_binary '',4,3),(27,'2026-06-11',33.5,'kg',1,4,0,'2026-06-08',_binary '',8,1),(28,'2026-06-14',5.29,'L',1,12,0,'2026-06-06',_binary '',18,1),(29,'2026-06-18',41.9,'kg',1,4,0,'2026-06-07',_binary '',20,2),(30,'2026-11-09',3.1,'g',340,12,0,'2026-05-30',_binary '',42,3),(31,'2026-09-09',7.9,'L',2,12,0,'2026-06-04',_binary '',50,3),(32,'2027-05-09',1.1,'ml',500,24,0,'2026-05-25',_binary '',52,2),(33,'2027-08-09',26.34,'kg',5,14,0,'2026-06-09',_binary '',5,1),(34,'2027-05-09',6.86,'kg',1,17,0,'2026-06-09',_binary '',6,2),(35,'2027-01-09',9.38,'L',2,14,0,'2026-06-09',_binary '',9,3),(36,'2026-06-15',13,'kg',1,11,0,'2026-06-09',_binary '',16,1),(37,'2027-09-09',4.14,'g',500,22,0,'2026-06-09',_binary '',24,2),(38,'2026-07-04',85.79,'kg',20,3,0,'2026-06-09',_binary '',39,3),(75,'2026-07-21',29.72,'kg',5,7,0,'2026-01-01',_binary '',29,2),(76,'2026-12-03',40.79,'kg',5,7,0,'2026-01-02',_binary '',30,2),(77,'2026-07-23',28.62,'kg',1,6,0,'2026-01-03',_binary '',31,2),(78,'2027-02-17',34.64,'kg',1,6,0,'2026-01-03',_binary '',32,2),(79,'2026-10-07',47.86,'kg',1,4,0,'2026-01-03',_binary '',33,1),(80,'2026-09-20',43.5,'kg',1,4,0,'2026-01-02',_binary '',34,1),(81,'2026-12-01',27.76,'kg',1,6,0,'2026-01-02',_binary '',35,4),(82,'2027-06-12',38.12,'kg',1,6,0,'2026-01-03',_binary '',36,4),(83,'2026-08-22',47.91,'kg',1,4,0,'2026-01-03',_binary '',35,4),(84,'2026-07-24',18.72,'kg',1,2,0,'2026-01-03',_binary '',37,1),(86,'2027-02-06',11.47,'g',50,1,0,'2026-01-03',_binary '',39,2),(87,'2026-12-04',17.84,'g',50,1,0,'2026-01-02',_binary '',40,2),(88,'2027-03-24',17.51,'g',50,1,0,'2026-01-07',_binary '',40,2),(89,'2026-08-25',20.39,'g',340,7,0,'2026-01-03',_binary '',41,1),(91,'2027-03-16',13.89,'g',340,3,0,'2026-01-04',_binary '',41,1),(92,'2026-09-05',32.39,'ml',750,1,0,'2026-01-02',_binary '',43,4),(93,'2027-02-01',26.04,'ml',750,1,0,'2026-01-01',_binary '',44,4),(94,'2027-01-17',5.69,'ml',750,1,0,'2026-01-02',_binary '',44,4),(95,'2027-02-13',30.23,'ml',900,3,0,'2026-01-02',_binary '',45,3),(96,'2027-02-20',25.84,'ml',900,3,0,'2026-01-03',_binary '',46,3),(97,'2026-12-05',36.09,'ml',900,2,0,'2026-01-07',_binary '',45,3),(98,'2027-06-12',32.88,'ml',500,1,0,'2026-01-02',_binary '',47,4),(99,'2026-07-22',24.59,'ml',500,1,0,'2026-01-03',_binary '',48,4),(100,'2026-08-14',34.86,'ml',500,1,0,'2026-01-01',_binary '',47,4),(101,'2026-09-24',35.96,'L',2,13,0,'2026-01-01',_binary '',49,1),(102,'2026-08-28',26.04,'L',2,13,0,'2026-01-02',_binary '',50,1),(103,'2026-10-19',28.09,'L',2,10,0,'2026-01-05',_binary '',50,1),(104,'2026-07-06',22.76,'kg',1,27,0,'2026-01-01',_binary '',51,3),(105,'2026-07-26',19.62,'kg',1,27,0,'2026-01-03',_binary '',52,3),(106,'2026-10-26',14.26,'L',2,9,0,'2026-01-02',_binary '',53,3),(112,'2027-02-18',27.76,'ml',900,4,0,'2026-01-08',_binary '',45,1),(114,'2026-10-18',21.51,'kg',5,17,0,'2026-01-09',_binary '',29,3),(115,'2027-06-30',21.83,'ml',750,3,0,'2026-01-09',_binary '',44,4),(123,'2027-06-16',33.29,'kg',1,9,0,'2026-01-10',_binary '',34,4),(124,'2027-04-20',21.13,'ml',500,3,0,'2026-01-10',_binary '',48,3),(125,'2027-01-10',20.17,'kg',1,4,0,'2026-01-12',_binary '',38,2),(126,'2027-02-04',25.68,'ml',900,3,0,'2026-01-13',_binary '',46,3),(129,'2026-06-28',51.05,'kg',1,10,0,'2026-01-14',_binary '',36,4),(130,'2026-08-08',9.29,'g',50,1,0,'2026-01-14',_binary '',40,4),(131,'2027-05-12',32.71,'kg',1,8,0,'2026-01-15',_binary '',32,1),(132,'2026-12-28',41,'ml',500,2,0,'2026-01-15',_binary '',48,3),(137,'2027-01-16',16.48,'g',50,1,0,'2026-01-17',_binary '',40,1),(140,'2026-09-01',29.44,'kg',1,8,0,'2026-01-18',_binary '',33,3),(141,'2027-01-24',18.99,'ml',750,1,0,'2026-01-18',_binary '',43,1),(144,'2026-10-26',57.56,'kg',1,11,0,'2026-01-19',_binary '',35,4),(145,'2026-09-02',23.79,'kg',1,45,0,'2026-01-19',_binary '',51,4),(146,'2026-10-28',16.84,'g',50,2,0,'2026-01-20',_binary '',40,2),(147,'2026-11-04',13.94,'g',340,17,0,'2026-01-20',_binary '',41,3),(148,'2026-08-19',26.21,'ml',900,6,0,'2026-01-20',_binary '',45,1),(152,'2026-06-16',40.11,'kg',1,9,0,'2026-01-21',_binary '',32,3),(155,'2027-03-31',49.4,'kg',5,19,0,'2026-01-22',_binary '',29,1),(156,'2026-11-23',58.79,'kg',1,8,0,'2026-01-22',_binary '',35,4),(157,'2026-09-20',27.59,'ml',500,3,0,'2026-01-22',_binary '',47,2),(161,'2026-09-06',26.14,'kg',1,6,0,'2026-01-23',_binary '',37,2),(162,'2027-03-19',18.57,'ml',750,4,0,'2026-01-23',_binary '',43,1),(168,'2027-01-28',18.63,'g',340,28,0,'2026-01-23',_binary '',41,2),(170,'2027-03-17',21.69,'g',50,3,0,'2026-01-25',_binary '',39,3),(171,'2026-06-29',26.29,'ml',900,3,0,'2026-01-25',_binary '',46,3),(172,'2027-06-26',38.15,'ml',500,1,0,'2026-01-25',_binary '',48,3),(173,'2026-09-09',29.37,'L',2,22,0,'2026-01-25',_binary '',49,3),(177,'2027-04-14',51.48,'kg',1,7,0,'2026-01-26',_binary '',33,2),(181,'2026-10-17',38.93,'kg',1,11,0,'2026-01-27',_binary '',32,3),(188,'2026-09-22',33.63,'ml',900,3,0,'2026-01-29',_binary '',45,4),(190,'2026-11-24',27.14,'ml',750,4,0,'2026-01-30',_binary '',43,2),(191,'2027-03-16',17.99,'ml',500,4,0,'2026-01-30',_binary '',48,4),(195,'2027-06-02',17.67,'g',50,2,0,'2026-01-31',_binary '',39,2),(196,'2027-02-28',28.17,'ml',900,5,0,'2026-01-31',_binary '',45,2),(200,'2027-03-26',32.42,'kg',1,9,0,'2026-02-01',_binary '',32,4),(201,'2027-07-08',43.34,'kg',1,7,0,'2026-02-01',_binary '',33,1),(202,'2026-09-18',23.18,'L',2,23,0,'2026-02-01',_binary '',50,1),(208,'2026-08-18',14.71,'kg',1,6,0,'2026-02-02',_binary '',38,3),(210,'2026-09-12',29.11,'ml',750,4,0,'2026-02-03',_binary '',43,1),(214,'2027-05-01',36.07,'kg',1,9,0,'2026-02-04',_binary '',36,1),(215,'2026-07-31',5.95,'g',340,16,0,'2026-02-04',_binary '',41,2),(216,'2026-08-10',19.84,'g',50,2,0,'2026-02-05',_binary '',39,1),(217,'2027-07-16',36.82,'kg',1,7,0,'2026-02-06',_binary '',34,4),(218,'2026-11-01',23.36,'ml',750,3,0,'2026-02-06',_binary '',43,2),(219,'2027-01-18',20.86,'ml',500,3,0,'2026-02-06',_binary '',48,1),(224,'2026-08-14',9.23,'kg',1,4,0,'2026-02-07',_binary '',38,4),(225,'2027-05-13',7.95,'ml',750,1,0,'2026-02-07',_binary '',43,4),(226,'2027-01-22',31.94,'ml',900,3,0,'2026-02-07',_binary '',45,4),(227,'2026-11-11',18.71,'kg',1,45,0,'2026-02-07',_binary '',51,3),(233,'2026-09-11',17.94,'L',2,14,0,'2026-02-08',_binary '',54,4),(239,'2026-08-12',13.65,'g',340,18,0,'2026-02-09',_binary '',41,2),(240,'2026-06-27',25.59,'ml',900,5,0,'2026-02-09',_binary '',46,4),(241,'2026-09-25',24.3,'L',2,20,0,'2026-02-09',_binary '',50,4),(242,'2026-11-16',13.13,'g',50,3,0,'2026-02-10',_binary '',39,3),(252,'2027-03-09',48.23,'kg',1,11,0,'2026-02-11',_binary '',31,2),(254,'2027-02-10',26.36,'ml',750,2,0,'2026-02-12',_binary '',44,4),(255,'2027-08-01',25.68,'ml',900,5,0,'2026-02-12',_binary '',46,4),(256,'2026-10-11',17.17,'ml',500,3,0,'2026-02-12',_binary '',48,4),(260,'2026-09-19',44.13,'kg',1,7,0,'2026-02-13',_binary '',34,1),(262,'2027-06-03',28.05,'kg',1,3,0,'2026-02-13',_binary '',37,2),(269,'2026-11-21',48.84,'kg',5,17,0,'2026-02-16',_binary '',29,2),(270,'2026-06-11',40.55,'ml',500,3,0,'2026-02-16',_binary '',47,3),(273,'2027-07-24',11.38,'g',50,1,0,'2026-02-17',_binary '',40,3),(274,'2026-10-12',11.59,'g',340,17,0,'2026-02-17',_binary '',41,2),(275,'2026-11-19',18.32,'kg',1,44,0,'2026-02-17',_binary '',51,4),(281,'2026-11-26',43.14,'kg',1,8,0,'2026-02-18',_binary '',32,1),(282,'2027-07-20',55.29,'kg',1,6,0,'2026-02-18',_binary '',33,4),(283,'2027-01-07',23.55,'kg',1,9,0,'2026-02-18',_binary '',36,3),(284,'2026-12-17',13.1,'kg',1,3,0,'2026-02-18',_binary '',37,3),(285,'2027-05-04',15.08,'g',50,2,0,'2026-02-18',_binary '',40,1),(286,'2027-04-19',36.67,'ml',900,5,0,'2026-02-18',_binary '',46,1),(290,'2027-04-05',21.1,'ml',750,1,0,'2026-02-19',_binary '',44,4),(292,'2026-12-14',35.66,'L',2,13,0,'2026-02-20',_binary '',53,2),(297,'2026-12-05',16.92,'ml',500,3,0,'2026-02-21',_binary '',48,1),(300,'2027-01-14',27.27,'kg',1,10,0,'2026-02-23',_binary '',32,4),(301,'2027-08-05',34.32,'kg',1,7,0,'2026-02-23',_binary '',33,3),(302,'2027-02-18',44.34,'kg',1,8,0,'2026-02-23',_binary '',35,1),(303,'2026-07-11',24.74,'kg',1,6,0,'2026-02-23',_binary '',37,1),(304,'2027-08-02',28.62,'g',50,3,0,'2026-02-23',_binary '',39,4),(305,'2027-06-24',40.64,'ml',900,5,0,'2026-02-23',_binary '',46,1),(307,'2026-12-25',15.22,'g',340,18,0,'2026-02-24',_binary '',41,1),(308,'2026-09-29',18.9,'ml',750,1,0,'2026-02-24',_binary '',44,4),(311,'2026-09-24',45.63,'kg',1,6,0,'2026-02-25',_binary '',34,2),(312,'2026-08-21',33.03,'L',2,21,0,'2026-02-25',_binary '',50,4),(321,'2026-08-03',27.64,'ml',500,2,0,'2026-02-26',_binary '',48,3),(322,'2026-08-18',35.77,'L',2,16,0,'2026-02-26',_binary '',53,1),(324,'2027-03-08',35.63,'kg',5,17,0,'2026-02-27',_binary '',29,1),(327,'2027-07-13',29.24,'ml',900,5,0,'2026-02-28',_binary '',46,2),(328,'2026-07-10',21.62,'ml',500,3,0,'2026-02-28',_binary '',47,4),(334,'2027-01-13',53.7,'kg',1,9,0,'2026-03-02',_binary '',31,1),(335,'2027-07-13',21.08,'kg',1,5,0,'2026-03-02',_binary '',38,2),(336,'2026-06-08',17.75,'g',50,2,0,'2026-03-02',_binary '',40,3),(337,'2027-06-17',29.49,'ml',750,3,0,'2026-03-02',_binary '',43,3),(338,'2026-12-27',16.08,'ml',900,4,0,'2026-03-02',_binary '',45,3),(343,'2027-06-03',48.99,'kg',1,8,0,'2026-03-04',_binary '',33,2),(344,'2027-01-28',40.76,'kg',1,8,0,'2026-03-04',_binary '',35,2),(345,'2027-05-25',21.73,'g',340,17,0,'2026-03-04',_binary '',42,4),(346,'2027-05-01',28.31,'ml',500,3,0,'2026-03-04',_binary '',48,2),(350,'2026-07-18',16.53,'kg',1,42,0,'2026-03-05',_binary '',52,1),(357,'2026-09-09',18.91,'ml',750,1,0,'2026-03-07',_binary '',43,4),(360,'2027-04-23',46.3,'kg',5,19,0,'2026-03-08',_binary '',30,4),(361,'2027-03-30',18.24,'kg',1,4,0,'2026-03-08',_binary '',37,1),(362,'2026-12-29',19.57,'ml',750,2,0,'2026-03-08',_binary '',43,2),(363,'2027-02-19',36.7,'ml',900,5,0,'2026-03-08',_binary '',46,2),(364,'2026-11-15',20.9,'L',2,20,0,'2026-03-08',_binary '',49,1),(365,'2026-06-12',49.41,'kg',1,10,0,'2026-03-09',_binary '',32,3),(366,'2027-02-08',39.48,'kg',1,10,0,'2026-03-09',_binary '',36,4),(367,'2026-08-31',7.64,'g',50,1,0,'2026-03-09',_binary '',40,2),(371,'2027-05-07',49.5,'kg',1,6,0,'2026-03-10',_binary '',34,2),(382,'2026-10-11',20.68,'ml',500,1,0,'2026-03-12',_binary '',48,3),(383,'2026-09-25',32.02,'L',2,13,0,'2026-03-12',_binary '',54,1),(387,'2027-07-08',54.95,'kg',1,6,0,'2026-03-13',_binary '',33,2),(388,'2027-04-22',14.84,'g',340,18,0,'2026-03-13',_binary '',42,3),(389,'2027-01-04',15.82,'ml',900,6,0,'2026-03-13',_binary '',46,3),(390,'2026-10-04',41.34,'kg',5,20,0,'2026-03-14',_binary '',30,3),(391,'2027-06-27',21.24,'kg',1,3,0,'2026-03-14',_binary '',38,1),(392,'2026-07-05',12.29,'ml',750,1,0,'2026-03-14',_binary '',43,4),(396,'2026-09-23',39.64,'kg',1,11,0,'2026-03-15',_binary '',32,2),(397,'2026-12-29',36.93,'kg',1,11,0,'2026-03-15',_binary '',36,1),(398,'2027-04-27',13.35,'ml',750,1,0,'2026-03-15',_binary '',43,4),(399,'2026-12-03',15.1,'L',2,22,0,'2026-03-15',_binary '',50,2),(402,'2026-10-13',44.66,'kg',1,6,0,'2026-03-16',_binary '',34,4),(403,'2026-06-18',19.01,'g',50,1,0,'2026-03-16',_binary '',39,4),(404,'2027-07-23',21.67,'ml',500,2,0,'2026-03-16',_binary '',47,4),(415,'2027-05-20',13.26,'g',340,18,0,'2026-03-18',_binary '',42,2),(416,'2026-07-09',29.38,'ml',750,3,0,'2026-03-18',_binary '',44,3),(419,'2026-09-06',13.28,'kg',1,5,0,'2026-03-19',_binary '',38,2),(420,'2026-06-30',24.41,'ml',900,4,0,'2026-03-19',_binary '',45,1),(428,'2026-12-21',29.47,'kg',1,10,0,'2026-03-20',_binary '',36,2),(430,'2026-11-21',38.08,'kg',1,8,0,'2026-03-21',_binary '',33,3),(433,'2027-09-11',14.83,'g',50,1,0,'2026-03-22',_binary '',39,1),(434,'2027-04-27',20.4,'ml',750,3,0,'2026-03-22',_binary '',44,4),(437,'2027-08-19',39.67,'ml',500,1,0,'2026-03-23',_binary '',47,1),(443,'2027-08-01',35.93,'kg',5,19,0,'2026-03-24',_binary '',29,3),(444,'2027-02-23',23.13,'kg',1,5,0,'2026-03-24',_binary '',37,3),(445,'2027-01-25',28.44,'ml',900,3,0,'2026-03-24',_binary '',45,2),(446,'2027-01-15',24.71,'g',340,16,0,'2026-03-25',_binary '',41,2),(447,'2026-07-26',17.12,'L',2,14,0,'2026-03-25',_binary '',53,4),(450,'2026-07-30',34.58,'kg',1,10,0,'2026-03-26',_binary '',31,2),(451,'2026-10-09',43.67,'kg',1,8,0,'2026-03-26',_binary '',33,4),(452,'2027-09-16',18.04,'ml',750,1,0,'2026-03-26',_binary '',44,4),(457,'2026-08-18',8.99,'ml',750,2,0,'2026-03-27',_binary '',44,3),(461,'2027-03-08',31.69,'kg',1,8,0,'2026-03-28',_binary '',36,4),(462,'2026-07-10',27.54,'g',50,3,0,'2026-03-28',_binary '',39,3),(463,'2027-01-01',19.02,'L',2,23,0,'2026-03-28',_binary '',50,3),(467,'2026-07-15',38.66,'ml',900,4,0,'2026-03-29',_binary '',46,4),(468,'2027-07-25',31.81,'ml',500,1,0,'2026-03-29',_binary '',47,2),(474,'2027-07-31',46.93,'kg',1,8,0,'2026-03-31',_binary '',31,2),(475,'2027-07-24',25.62,'kg',1,7,0,'2026-03-31',_binary '',33,4),(476,'2027-04-24',28.76,'kg',1,3,0,'2026-03-31',_binary '',38,2),(477,'2026-09-06',11,'g',50,2,0,'2026-03-31',_binary '',40,4),(478,'2027-07-04',18.81,'g',340,17,0,'2026-03-31',_binary '',41,4),(482,'2026-08-19',45,'kg',5,17,0,'2026-04-01',_binary '',29,3),(483,'2026-12-08',25.49,'L',2,15,0,'2026-04-01',_binary '',54,4),(489,'2027-04-19',14.07,'ml',750,4,0,'2026-04-02',_binary '',43,3),(490,'2026-10-28',33.17,'ml',900,5,0,'2026-04-02',_binary '',46,1),(494,'2027-02-28',48.95,'kg',1,9,0,'2026-04-03',_binary '',35,3),(495,'2027-03-01',19.69,'g',50,1,0,'2026-04-03',_binary '',39,4),(496,'2027-02-23',31.49,'ml',500,2,0,'2026-04-03',_binary '',48,1),(500,'2027-09-16',8.67,'g',340,28,0,'2026-04-04',_binary '',42,4),(506,'2026-10-26',23.67,'kg',1,11,0,'2026-04-05',_binary '',32,4),(507,'2027-07-08',43.04,'kg',1,8,0,'2026-04-05',_binary '',34,3),(508,'2026-12-12',24.55,'kg',1,4,0,'2026-04-05',_binary '',38,1),(509,'2026-08-16',17.15,'ml',750,3,0,'2026-04-05',_binary '',43,3),(516,'2027-07-23',43.82,'kg',1,11,0,'2026-04-07',_binary '',36,1),(517,'2027-01-21',29.25,'g',50,3,0,'2026-04-07',_binary '',39,1),(518,'2027-02-18',25.12,'ml',500,2,0,'2026-04-07',_binary '',47,1),(519,'2026-11-21',32.1,'kg',1,45,0,'2026-04-07',_binary '',51,2),(522,'2026-09-01',41.72,'kg',1,11,0,'2026-04-08',_binary '',31,2),(523,'2026-10-18',31.49,'ml',750,2,0,'2026-04-08',_binary '',43,2),(524,'2026-12-20',35.78,'ml',900,6,0,'2026-04-08',_binary '',46,2),(528,'2027-06-28',26.95,'kg',1,3,0,'2026-04-10',_binary '',38,1),(531,'2027-01-28',38.45,'kg',5,18,0,'2026-04-11',_binary '',29,3),(536,'2026-08-08',55.6,'kg',1,7,0,'2026-04-12',_binary '',34,4),(537,'2027-08-05',18.42,'g',50,4,0,'2026-04-12',_binary '',39,1),(538,'2027-03-28',11.7,'ml',750,2,0,'2026-04-12',_binary '',44,3),(541,'2027-10-02',38.86,'kg',1,8,0,'2026-04-13',_binary '',32,3),(542,'2026-07-26',20.97,'ml',900,6,0,'2026-04-13',_binary '',46,1),(543,'2027-06-28',33.91,'ml',500,4,0,'2026-04-13',_binary '',47,3),(545,'2027-08-17',27.01,'g',50,4,0,'2026-04-14',_binary '',39,3),(546,'2027-06-24',23.09,'g',340,18,0,'2026-04-14',_binary '',41,2),(554,'2027-03-27',24.12,'ml',750,2,0,'2026-04-16',_binary '',44,3),(555,'2026-10-09',31.14,'ml',500,3,0,'2026-04-16',_binary '',47,4),(556,'2026-12-29',11.27,'L',2,20,0,'2026-04-16',_binary '',49,4),(557,'2026-10-14',34.43,'L',2,14,0,'2026-04-16',_binary '',53,4),(561,'2027-09-03',36.98,'kg',5,17,0,'2026-04-17',_binary '',29,3),(562,'2027-06-21',43.56,'kg',1,7,0,'2026-04-17',_binary '',33,3),(564,'2026-10-17',21.91,'kg',1,11,0,'2026-04-18',_binary '',35,3),(567,'2026-10-24',11.54,'kg',1,5,0,'2026-04-19',_binary '',38,2),(568,'2026-10-16',16.18,'ml',900,5,0,'2026-04-19',_binary '',45,3),(571,'2027-07-12',21.21,'g',340,16,0,'2026-04-20',_binary '',41,2),(577,'2026-08-29',48.5,'kg',1,9,0,'2026-04-21',_binary '',32,2),(578,'2027-04-26',23.21,'kg',1,6,0,'2026-04-21',_binary '',38,2),(579,'2026-12-16',31.67,'g',50,4,0,'2026-04-21',_binary '',39,3),(580,'2026-10-09',11.46,'ml',750,1,0,'2026-04-21',_binary '',44,4),(581,'2027-04-01',26.72,'ml',500,4,0,'2026-04-21',_binary '',48,1),(582,'2027-01-31',20.18,'L',2,23,0,'2026-04-21',_binary '',49,1),(586,'2027-02-10',11.62,'L',2,14,0,'2026-04-22',_binary '',53,2),(591,'2026-09-30',57.96,'kg',1,11,0,'2026-04-24',_binary '',32,3),(592,'2027-06-05',37.69,'kg',1,9,0,'2026-04-24',_binary '',33,2),(594,'2027-02-01',38.21,'kg',5,17,0,'2026-04-25',_binary '',30,1),(595,'2026-09-11',35.61,'ml',900,3,0,'2026-04-25',_binary '',45,2),(598,'2026-09-25',5.35,'ml',750,4,0,'2026-04-26',_binary '',44,1),(599,'2027-08-19',33.84,'ml',500,3,0,'2026-04-26',_binary '',48,3),(601,'2027-07-13',16.49,'g',50,4,0,'2026-04-27',_binary '',39,4),(602,'2026-08-16',24.18,'kg',1,42,0,'2026-04-27',_binary '',51,2),(606,'2027-06-02',27.24,'kg',1,3,0,'2026-04-28',_binary '',37,1),(607,'2027-01-14',23.23,'ml',500,4,0,'2026-04-28',_binary '',47,4),(608,'2026-07-27',15.49,'L',2,21,0,'2026-04-28',_binary '',50,2),(609,'2026-08-22',28.03,'L',2,15,0,'2026-04-28',_binary '',53,1),(614,'2027-05-30',42.08,'kg',1,8,0,'2026-04-29',_binary '',31,1),(615,'2026-11-07',31.49,'kg',1,8,0,'2026-04-29',_binary '',35,4),(616,'2026-12-05',33.18,'kg',1,6,0,'2026-04-29',_binary '',38,4),(625,'2027-03-15',11.55,'g',50,2,0,'2026-04-30',_binary '',39,2),(626,'2026-10-16',14.7,'g',340,15,0,'2026-04-30',_binary '',41,2),(627,'2027-08-19',14.32,'ml',750,4,0,'2026-04-30',_binary '',43,1),(628,'2027-07-24',25.36,'ml',900,6,0,'2026-04-30',_binary '',46,1),(629,'2027-05-08',25.6,'kg',5,18,0,'2026-05-01',_binary '',29,1),(630,'2027-08-23',26.83,'kg',1,9,0,'2026-05-01',_binary '',33,1),(632,'2026-11-09',34.44,'kg',1,11,0,'2026-05-02',_binary '',35,2),(634,'2026-06-14',59.43,'kg',1,6,0,'2026-05-03',_binary '',20,4),(635,'2027-10-15',22.69,'ml',500,2,0,'2026-05-03',_binary '',47,2),(636,'2027-01-28',31.19,'L',2,16,0,'2026-05-03',_binary '',53,2),(637,'2026-06-17',67.29,'kg',1,3,0,'2026-05-04',_binary '',22,4),(638,'2027-01-22',24.55,'kg',1,9,0,'2026-05-04',_binary '',31,1),(639,'2026-12-26',13.85,'kg',1,6,0,'2026-05-04',_binary '',38,1),(640,'2027-03-03',33.95,'ml',900,4,0,'2026-05-04',_binary '',46,2),(647,'2027-09-17',17.25,'g',50,1,0,'2026-05-05',_binary '',40,4),(649,'2027-07-12',42.65,'kg',1,8,0,'2026-05-06',_binary '',32,2),(650,'2026-11-15',29.81,'L',2,22,0,'2026-05-06',_binary '',49,1),(652,'2027-05-14',24.49,'g',340,15,0,'2026-05-07',_binary '',42,2),(653,'2027-10-05',17.32,'ml',750,1,0,'2026-05-07',_binary '',43,1),(654,'2026-10-01',13.93,'kg',1,43,0,'2026-05-07',_binary '',51,3),(655,'2026-10-26',12.09,'L',2,14,0,'2026-05-07',_binary '',53,3),(660,'2027-06-14',31.1,'kg',1,8,0,'2026-05-08',_binary '',34,1),(661,'2026-10-25',40.82,'kg',1,8,0,'2026-05-08',_binary '',35,2),(662,'2026-08-09',40.13,'ml',500,3,0,'2026-05-08',_binary '',47,1),(664,'2026-10-21',29.69,'kg',5,17,0,'2026-05-09',_binary '',30,2),(665,'2026-10-31',41.61,'kg',1,8,0,'2026-05-09',_binary '',32,3),(666,'2027-10-27',47.45,'kg',1,10,0,'2026-05-09',_binary '',36,2),(670,'2026-09-06',19.25,'g',50,3,0,'2026-05-10',_binary '',39,3),(671,'2026-11-12',24.27,'ml',900,6,0,'2026-05-10',_binary '',46,3),(672,'2027-03-25',18.54,'ml',500,2,0,'2026-05-10',_binary '',47,1),(674,'2026-06-12',28.51,'kg',1,3,0,'2026-05-11',_binary '',22,2),(675,'2027-05-02',21.71,'kg',1,4,0,'2026-05-11',_binary '',37,2),(676,'2027-09-22',18.42,'g',340,17,0,'2026-05-11',_binary '',41,4),(677,'2027-01-21',8.65,'L',2,21,0,'2026-05-11',_binary '',50,4),(679,'2026-06-07',48.33,'kg',1,5,0,'2026-05-12',_binary '',19,3),(685,'2027-05-15',35.03,'kg',1,7,0,'2026-05-13',_binary '',34,2),(686,'2026-09-10',16.92,'ml',750,4,0,'2026-05-13',_binary '',44,3),(687,'2026-10-16',21.1,'L',2,14,0,'2026-05-13',_binary '',53,1),(689,'2026-06-17',73.18,'kg',1,6,0,'2026-05-14',_binary '',20,1),(690,'2026-12-10',35.63,'kg',1,8,0,'2026-05-14',_binary '',36,3),(691,'2027-10-17',18.47,'g',50,3,0,'2026-05-14',_binary '',39,4),(695,'2026-11-26',42.91,'kg',5,20,0,'2026-05-15',_binary '',29,1),(696,'2027-04-28',30.49,'kg',1,10,0,'2026-05-15',_binary '',32,1),(697,'2027-10-21',25.61,'ml',900,4,0,'2026-05-15',_binary '',45,2),(698,'2026-10-20',30.76,'ml',500,1,0,'2026-05-15',_binary '',48,4),(700,'2026-06-09',38.3,'kg',1,5,0,'2026-05-16',_binary '',21,1),(701,'2026-11-17',22.35,'kg',1,3,0,'2026-05-16',_binary '',38,1),(702,'2026-11-14',12.72,'g',340,17,0,'2026-05-16',_binary '',41,3),(705,'2027-03-26',16.22,'g',50,4,0,'2026-05-17',_binary '',40,3),(708,'2026-06-07',39.73,'kg',1,4,0,'2026-05-18',_binary '',26,4),(710,'2027-10-31',21.46,'ml',750,3,0,'2026-05-18',_binary '',44,1),(711,'2026-08-22',25.93,'L',2,20,0,'2026-05-18',_binary '',50,4),(712,'2026-07-16',17.86,'kg',1,42,7,'2026-05-18',_binary '',52,3),(716,'2026-06-30',52.94,'kg',1,4,0,'2026-05-19',_binary '',19,4),(717,'2027-01-10',31.32,'kg',1,9,0,'2026-05-19',_binary '',33,4),(718,'2027-06-06',37.76,'kg',1,10,0,'2026-05-19',_binary '',35,4),(719,'2027-02-26',36.98,'ml',500,1,0,'2026-05-19',_binary '',47,1),(721,'2027-05-30',39.6,'ml',900,5,0,'2026-05-20',_binary '',46,3),(722,'2027-02-22',16.49,'L',2,15,0,'2026-05-20',_binary '',53,2),(728,'2027-01-09',28.08,'L',2,22,0,'2026-05-20',_binary '',54,4),(730,'2026-06-07',71.88,'kg',1,6,0,'2026-05-21',_binary '',23,4),(731,'2027-05-15',49.82,'kg',5,18,0,'2026-05-21',_binary '',30,3),(732,'2026-06-07',38.71,'kg',1,6,0,'2026-05-22',_binary '',6,4),(734,'2026-09-16',5.79,'g',340,18,0,'2026-05-22',_binary '',41,4),(735,'2026-06-12',48.4,'kg',1,4,0,'2026-05-23',_binary '',28,3),(736,'2026-10-07',42.12,'kg',1,9,0,'2026-05-23',_binary '',34,3),(737,'2027-05-30',9.49,'kg',1,4,0,'2026-05-23',_binary '',38,2),(738,'2026-08-22',15.4,'ml',750,2,0,'2026-05-23',_binary '',44,4),(739,'2026-06-09',64.38,'kg',1,4,0,'2026-05-24',_binary '',26,2),(740,'2027-06-22',24.41,'g',50,3,0,'2026-05-24',_binary '',40,4),(741,'2027-01-04',28.43,'ml',500,4,0,'2026-05-24',_binary '',48,4),(742,'2026-06-10',32.89,'kg',1,10,0,'2026-05-25',_binary '',2,1),(744,'2026-06-08',41.81,'kg',1,8,0,'2026-05-26',_binary '',4,4),(745,'2026-06-12',65.5,'kg',1,9,0,'2026-05-26',_binary '',9,4),(748,'2026-06-21',42.92,'kg',1,6,0,'2026-05-26',_binary '',19,3),(749,'2026-06-12',57.22,'kg',1,5,0,'2026-05-26',_binary '',22,4),(750,'2027-01-11',51.24,'kg',1,9,0,'2026-05-26',_binary '',31,1),(751,'2026-10-02',50.28,'kg',1,10,0,'2026-05-26',_binary '',35,4),(752,'2027-06-17',29.12,'ml',900,3,0,'2026-05-26',_binary '',46,3),(753,'2027-02-01',28.38,'L',2,22,0,'2026-05-26',_binary '',49,4),(755,'2026-06-08',67.6,'kg',1,6,0,'2026-05-27',_binary '',23,2),(756,'2026-12-27',31.87,'ml',500,3,0,'2026-05-27',_binary '',48,3),(757,'2026-06-17',64.87,'kg',1,5,0,'2026-05-28',_binary '',28,2),(758,'2027-01-09',24.62,'kg',5,19,9,'2026-05-28',_binary '',30,3),(759,'2026-10-14',49.05,'kg',1,7,0,'2026-05-28',_binary '',34,2),(760,'2027-01-01',23.11,'ml',750,1,0,'2026-05-28',_binary '',43,1),(761,'2026-10-10',25.71,'ml',500,4,0,'2026-05-28',_binary '',47,3),(762,'2027-03-09',20.44,'kg',1,45,18,'2026-05-29',_binary '',52,3),(763,'2026-06-17',43.4,'kg',1,11,0,'2026-05-30',_binary '',1,2),(764,'2026-06-14',53.27,'L',1,16,2,'2026-05-30',_binary '',17,2),(766,'2027-10-11',22.77,'kg',1,6,0,'2026-05-30',_binary '',37,1),(767,'2027-11-15',23.65,'g',50,4,0,'2026-05-30',_binary '',39,1),(768,'2027-04-25',21.7,'g',340,18,13,'2026-05-30',_binary '',41,1),(769,'2026-06-19',37.99,'kg',1,5,0,'2026-05-31',_binary '',4,4),(771,'2026-06-20',63.29,'kg',1,3,0,'2026-05-31',_binary '',22,3),(772,'2027-01-14',36.34,'kg',1,11,0,'2026-05-31',_binary '',36,3),(773,'2026-12-11',22.57,'ml',900,3,0,'2026-05-31',_binary '',45,4),(774,'2027-05-15',17.98,'ml',500,4,0,'2026-05-31',_binary '',48,1),(775,'2026-06-14',53.57,'kg',1,5,0,'2026-06-01',_binary '',6,4),(776,'2026-06-09',71.7,'kg',1,5,0,'2026-06-01',_binary '',7,3),(778,'2027-08-27',36.87,'kg',1,8,0,'2026-06-01',_binary '',32,4),(779,'2027-11-04',29.97,'kg',1,8,0,'2026-06-01',_binary '',33,2),(780,'2026-09-04',19.19,'L',2,21,12,'2026-06-01',_binary '',50,4),(781,'2026-06-22',50.04,'kg',1,5,0,'2026-06-02',_binary '',3,3),(782,'2026-06-09',20.06,'kg',1,8,3,'2026-06-02',_binary '',15,3),(783,'2026-06-12',41.65,'kg',1,3,0,'2026-06-02',_binary '',20,1),(784,'2026-06-12',40.23,'kg',1,4,0,'2026-06-02',_binary '',24,1),(785,'2026-10-20',28.47,'L',2,16,2,'2026-06-02',_binary '',54,2),(786,'2026-06-12',58.02,'kg',1,9,0,'2026-06-03',_binary '',9,1),(787,'2027-08-11',11.41,'g',50,4,0,'2026-06-03',_binary '',39,2),(788,'2027-05-28',9.32,'ml',750,2,0,'2026-06-03',_binary '',43,1),(789,'2026-06-22',49.39,'kg',1,5,0,'2026-06-03',_binary '',21,4),(790,'2026-06-22',44.64,'kg',1,6,0,'2026-06-03',_binary '',28,4),(791,'2026-06-12',11.42,'kg',1,17,11,'2026-06-03',_binary '',15,2),(792,'2027-01-13',21.73,'g',340,28,22,'2026-06-03',_binary '',42,4),(793,'2026-07-04',57.01,'kg',1,7,0,'2026-06-03',_binary '',20,4),(794,'2026-06-19',66.81,'kg',1,7,0,'2026-06-03',_binary '',8,2),(795,'2026-07-12',30.43,'L',1,23,9,'2026-06-03',_binary '',18,4),(796,'2026-06-20',68.61,'kg',1,5,3,'2026-06-04',_binary '',4,1),(797,'2026-06-14',37.49,'kg',1,7,1,'2026-06-04',_binary '',24,4),(798,'2027-11-12',43.97,'kg',1,10,1,'2026-06-04',_binary '',31,4),(799,'2027-04-06',23.92,'ml',500,2,0,'2026-06-04',_binary '',47,4),(800,'2026-06-07',12,'kg',1,16,13,'2026-06-05',_binary '',11,4),(801,'2026-11-20',34.06,'kg',1,10,6,'2026-06-05',_binary '',36,4),(802,'2027-03-13',23.89,'kg',1,4,0,'2026-06-05',_binary '',37,1),(803,'2027-06-24',22.93,'ml',900,3,0,'2026-06-05',_binary '',45,3),(804,'2026-06-22',54.77,'kg',1,4,1,'2026-06-06',_binary '',5,4),(805,'2027-06-18',26.94,'kg',1,9,6,'2026-06-06',_binary '',33,2),(806,'2026-07-15',48.73,'kg',1,4,0,'2026-06-07',_binary '',19,3),(807,'2026-06-19',58.7,'kg',1,4,4,'2026-06-07',_binary '',21,2),(808,'2026-06-10',40.5,'kg',1,3,3,'2026-06-07',_binary '',28,1),(809,'2026-06-27',30,'kg',1,8,8,'2026-06-08',_binary '',9,1),(810,'2026-06-13',13.26,'kg',1,6,5,'2026-06-08',_binary '',14,3),(811,'2027-05-15',23.8,'ml',900,4,4,'2026-06-08',_binary '',45,4),(812,'2026-10-02',30.86,'L',2,14,6,'2026-06-08',_binary '',53,2),(813,'2026-06-29',49.52,'kg',1,12,12,'2026-06-09',_binary '',2,1),(814,'2026-06-18',41.09,'kg',1,6,6,'2026-06-09',_binary '',7,4),(815,'2026-06-23',50.53,'kg',1,3,3,'2026-06-09',_binary '',26,1),(816,'2026-11-19',43.47,'kg',1,11,11,'2026-06-09',_binary '',32,2),(817,'2027-04-06',13.55,'ml',750,2,2,'2026-06-09',_binary '',43,2),(818,'2026-12-11',27.71,'ml',500,1,1,'2026-06-09',_binary '',47,3);
/*!40000 ALTER TABLE `lote` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `marca`
--

DROP TABLE IF EXISTS `marca`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `marca` (
  `idMarca` int NOT NULL AUTO_INCREMENT,
  `fkInsumo` int DEFAULT NULL,
  `fkFornecedor` int DEFAULT NULL,
  `nomeMarca` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idMarca`),
  KEY `fk_marca_insumo` (`fkInsumo`),
  KEY `fk_marca_fornecedor` (`fkFornecedor`),
  CONSTRAINT `fk_marca_fornecedor` FOREIGN KEY (`fkFornecedor`) REFERENCES `fornecedor` (`idFornecedor`),
  CONSTRAINT `fk_marca_insumo` FOREIGN KEY (`fkInsumo`) REFERENCES `insumo` (`idInsumo`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `marca`
--

LOCK TABLES `marca` WRITE;
/*!40000 ALTER TABLE `marca` DISABLE KEYS */;
INSERT INTO `marca` VALUES (1,1,2,'Sadia'),(2,1,2,'Seara'),(3,2,2,'Friboi'),(4,2,2,'Swift'),(5,3,2,'Aurora'),(6,3,2,'Perdigao'),(7,4,2,'Copacol'),(8,4,2,'Qualita'),(9,5,2,'Coqueiro'),(10,5,2,'Gomes da Costa'),(11,6,3,'Hortifruti Central'),(12,6,3,'Sitio do Joao'),(13,7,3,'Hortifruti Central'),(14,7,3,'Sitio do Joao'),(15,8,3,'Hortifruti Central'),(16,8,3,'Sitio do Joao'),(17,9,1,'Italac'),(18,9,1,'Piracanjuba'),(19,10,1,'Polenghi'),(20,10,1,'Tirolez'),(21,11,1,'Aviacao'),(22,11,1,'Vigor'),(23,12,2,'Seara'),(24,12,2,'Perdigao'),(25,13,2,'Aurora'),(26,13,2,'Seara'),(27,14,1,'Sadia'),(28,14,1,'Perdigao'),(29,15,3,'Camil'),(30,15,3,'Tio Joao'),(31,16,3,'Camil'),(32,16,3,'Kicaldo'),(33,17,3,'Dona Benta'),(34,17,3,'Sol'),(35,18,3,'Renata'),(36,18,3,'Adria'),(37,19,4,'Cisne'),(38,19,4,'Qualita'),(39,20,4,'Kitano'),(40,20,4,'Bombay'),(41,21,4,'Pomarola'),(42,21,4,'Elefante'),(43,22,4,'Castelo'),(44,22,4,'Qualita'),(45,23,4,'Liza'),(46,23,4,'Soya'),(47,24,4,'Gallo'),(48,24,4,'Andorinha'),(49,25,5,'Coca-Cola'),(50,25,5,'Antarctica'),(51,26,5,'Crystal'),(52,26,5,'Minalba'),(53,27,5,'Del Valle'),(54,27,5,'Maguary');
/*!40000 ALTER TABLE `marca` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rotina`
--

DROP TABLE IF EXISTS `rotina`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rotina` (
  `idRotina` int NOT NULL AUTO_INCREMENT,
  `titulo` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idRotina`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rotina`
--

LOCK TABLES `rotina` WRITE;
/*!40000 ALTER TABLE `rotina` DISABLE KEYS */;
/*!40000 ALTER TABLE `rotina` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rotinainsumo`
--

DROP TABLE IF EXISTS `rotinainsumo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rotinainsumo` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idRotina` int DEFAULT NULL,
  `idInsumo` int DEFAULT NULL,
  `quantidadeInsumo` int DEFAULT NULL,
  `unidadeMedida` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rotinaInsumo_rotina` (`idRotina`),
  KEY `fk_rotinaInsumo_insumo` (`idInsumo`),
  CONSTRAINT `fk_rotinaInsumo_insumo` FOREIGN KEY (`idInsumo`) REFERENCES `insumo` (`idInsumo`),
  CONSTRAINT `fk_rotinaInsumo_rotina` FOREIGN KEY (`idRotina`) REFERENCES `rotina` (`idRotina`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rotinainsumo`
--

LOCK TABLES `rotinainsumo` WRITE;
/*!40000 ALTER TABLE `rotinainsumo` DISABLE KEYS */;
/*!40000 ALTER TABLE `rotinainsumo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuario`
--

DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario` (
  `idUsuario` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `apelido` varchar(255) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `administrador` bit(1) DEFAULT NULL,
  PRIMARY KEY (`idUsuario`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
INSERT INTO `usuario` VALUES (1,'Carlos Eduardo Silva','carlos','$2a$10$sOq5iURNIZTC8YpXsxuHIuEeWD5YkTpzv88e8hvStcBsDmFaJyGqG',_binary ''),(2,'Ana Paula Souza','ana','$2a$10$Hk/9InXTjAEH2YDYpffop.o8BV/Gykae8j3e0l4i4cfPMFmzuVf76',_binary '\0'),(3,'Roberto Mendes','roberto','$2a$10$etQma57SzXkoYbgWOfOAP./IB90/sUp8.FEDW2IaSxEqfYZ/d.0x6',_binary '\0'),(4,'Toomate','toomate','$2a$10$Us8hLpHXsJ.HIpeoJF0kjOG3mAtnjTXOIqbrvXJ5brbgOSjcYGiAq',_binary '');
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_boleto_maior_valor_aberto`
--

DROP TABLE IF EXISTS `vw_boleto_maior_valor_aberto`;
/*!50001 DROP VIEW IF EXISTS `vw_boleto_maior_valor_aberto`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_boleto_maior_valor_aberto` AS SELECT 
 1 AS `idBoleto`,
 1 AS `descricao`,
 1 AS `categoria`,
 1 AS `pago`,
 1 AS `dataVencimento`,
 1 AS `dataPagamento`,
 1 AS `valor`,
 1 AS `fkFornecedor`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_cliente_maior_devedor`
--

DROP TABLE IF EXISTS `vw_cliente_maior_devedor`;
/*!50001 DROP VIEW IF EXISTS `vw_cliente_maior_devedor`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_cliente_maior_devedor` AS SELECT 
 1 AS `nome`,
 1 AS `telefone`,
 1 AS `TotalDevido`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_grafico_estoque_vs_minimo`
--

DROP TABLE IF EXISTS `vw_grafico_estoque_vs_minimo`;
/*!50001 DROP VIEW IF EXISTS `vw_grafico_estoque_vs_minimo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_grafico_estoque_vs_minimo` AS SELECT 
 1 AS `Insumo`,
 1 AS `EstoqueAtual`,
 1 AS `EstoqueMinimo`,
 1 AS `Status`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_kpi_boletos_mes_atual`
--

DROP TABLE IF EXISTS `vw_kpi_boletos_mes_atual`;
/*!50001 DROP VIEW IF EXISTS `vw_kpi_boletos_mes_atual`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_kpi_boletos_mes_atual` AS SELECT 
 1 AS `QtdBoletosMes`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_kpi_boletos_vencimento_proximo`
--

DROP TABLE IF EXISTS `vw_kpi_boletos_vencimento_proximo`;
/*!50001 DROP VIEW IF EXISTS `vw_kpi_boletos_vencimento_proximo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_kpi_boletos_vencimento_proximo` AS SELECT 
 1 AS `idBoleto`,
 1 AS `descricao`,
 1 AS `categoria`,
 1 AS `pago`,
 1 AS `dataVencimento`,
 1 AS `dataPagamento`,
 1 AS `valor`,
 1 AS `fkFornecedor`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_kpi_contas_atrasadas`
--

DROP TABLE IF EXISTS `vw_kpi_contas_atrasadas`;
/*!50001 DROP VIEW IF EXISTS `vw_kpi_contas_atrasadas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_kpi_contas_atrasadas` AS SELECT 
 1 AS `QtdAtrasadas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_kpi_estoque_baixo`
--

DROP TABLE IF EXISTS `vw_kpi_estoque_baixo`;
/*!50001 DROP VIEW IF EXISTS `vw_kpi_estoque_baixo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_kpi_estoque_baixo` AS SELECT 
 1 AS `Insumo`,
 1 AS `EstoqueTotal`,
 1 AS `qtdMinima`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_kpi_validade_proxima`
--

DROP TABLE IF EXISTS `vw_kpi_validade_proxima`;
/*!50001 DROP VIEW IF EXISTS `vw_kpi_validade_proxima`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_kpi_validade_proxima` AS SELECT 
 1 AS `Insumo`,
 1 AS `dataValidade`,
 1 AS `QtdAtual`,
 1 AS `DiasParaVencer`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_pedido_aberto_mais_antigo`
--

DROP TABLE IF EXISTS `vw_pedido_aberto_mais_antigo`;
/*!50001 DROP VIEW IF EXISTS `vw_pedido_aberto_mais_antigo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_pedido_aberto_mais_antigo` AS SELECT 
 1 AS `Cliente`,
 1 AS `dataCompra`,
 1 AS `valor`,
 1 AS `pedido`,
 1 AS `DiasEmAberto`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_predicao_falta_estoque`
--

DROP TABLE IF EXISTS `vw_predicao_falta_estoque`;
/*!50001 DROP VIEW IF EXISTS `vw_predicao_falta_estoque`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_predicao_falta_estoque` AS SELECT 
 1 AS `Insumo`,
 1 AS `EstoqueAtual`,
 1 AS `qtdMinima`,
 1 AS `MargemSeguranca`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_predicao_perda_validade`
--

DROP TABLE IF EXISTS `vw_predicao_perda_validade`;
/*!50001 DROP VIEW IF EXISTS `vw_predicao_perda_validade`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_predicao_perda_validade` AS SELECT 
 1 AS `Insumo`,
 1 AS `QtdNoLote`,
 1 AS `dataValidade`,
 1 AS `DiasRestantes`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_total_contas_semana`
--

DROP TABLE IF EXISTS `vw_total_contas_semana`;
/*!50001 DROP VIEW IF EXISTS `vw_total_contas_semana`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_total_contas_semana` AS SELECT 
 1 AS `ValorTotalSemana`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_total_divida_clientes`
--

DROP TABLE IF EXISTS `vw_total_divida_clientes`;
/*!50001 DROP VIEW IF EXISTS `vw_total_divida_clientes`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_total_divida_clientes` AS SELECT 
 1 AS `TotalReceber`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_total_entrada_estoque_semana`
--

DROP TABLE IF EXISTS `vw_total_entrada_estoque_semana`;
/*!50001 DROP VIEW IF EXISTS `vw_total_entrada_estoque_semana`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_total_entrada_estoque_semana` AS SELECT 
 1 AS `ValorTotalEntradas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_total_perda_validade`
--

DROP TABLE IF EXISTS `vw_total_perda_validade`;
/*!50001 DROP VIEW IF EXISTS `vw_total_perda_validade`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_total_perda_validade` AS SELECT 
 1 AS `ValorTotalPerda`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_total_valor_atrasado`
--

DROP TABLE IF EXISTS `vw_total_valor_atrasado`;
/*!50001 DROP VIEW IF EXISTS `vw_total_valor_atrasado`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_total_valor_atrasado` AS SELECT 
 1 AS `TotalDividaFornecedor`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `vw_boleto_maior_valor_aberto`
--

/*!50001 DROP VIEW IF EXISTS `vw_boleto_maior_valor_aberto`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_boleto_maior_valor_aberto` AS select `boleto`.`idBoleto` AS `idBoleto`,`boleto`.`descricao` AS `descricao`,`boleto`.`categoria` AS `categoria`,`boleto`.`pago` AS `pago`,`boleto`.`dataVencimento` AS `dataVencimento`,`boleto`.`dataPagamento` AS `dataPagamento`,`boleto`.`valor` AS `valor`,`boleto`.`fkFornecedor` AS `fkFornecedor` from `boleto` where (`boleto`.`pago` = 0) order by `boleto`.`valor` desc limit 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_cliente_maior_devedor`
--

/*!50001 DROP VIEW IF EXISTS `vw_cliente_maior_devedor`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_cliente_maior_devedor` AS select `c`.`nome` AS `nome`,`c`.`telefone` AS `telefone`,sum(`d`.`valor`) AS `TotalDevido` from (`cliente` `c` join `divida` `d` on((`c`.`idCliente` = `d`.`fkCliente`))) where (`d`.`pago` = 0) group by `c`.`idCliente`,`c`.`nome`,`c`.`telefone` order by `TotalDevido` desc limit 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_grafico_estoque_vs_minimo`
--

/*!50001 DROP VIEW IF EXISTS `vw_grafico_estoque_vs_minimo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_grafico_estoque_vs_minimo` AS select `i`.`nome` AS `Insumo`,coalesce(sum(`l`.`quantidadeAtual`),0) AS `EstoqueAtual`,`i`.`qtdMinima` AS `EstoqueMinimo`,(case when (coalesce(sum(`l`.`quantidadeAtual`),0) < `i`.`qtdMinima`) then 'Repor Urgente' else 'OK' end) AS `Status` from ((`insumo` `i` left join `marca` `m` on((`i`.`idInsumo` = `m`.`fkInsumo`))) left join `lote` `l` on((`m`.`idMarca` = `l`.`fkMarca`))) where (`i`.`ativo` = 1) group by `i`.`idInsumo`,`i`.`nome`,`i`.`qtdMinima` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kpi_boletos_mes_atual`
--

/*!50001 DROP VIEW IF EXISTS `vw_kpi_boletos_mes_atual`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kpi_boletos_mes_atual` AS select count(0) AS `QtdBoletosMes` from `boleto` where ((month(`boleto`.`dataVencimento`) = month(curdate())) and (year(`boleto`.`dataVencimento`) = year(curdate()))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kpi_boletos_vencimento_proximo`
--

/*!50001 DROP VIEW IF EXISTS `vw_kpi_boletos_vencimento_proximo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kpi_boletos_vencimento_proximo` AS select `boleto`.`idBoleto` AS `idBoleto`,`boleto`.`descricao` AS `descricao`,`boleto`.`categoria` AS `categoria`,`boleto`.`pago` AS `pago`,`boleto`.`dataVencimento` AS `dataVencimento`,`boleto`.`dataPagamento` AS `dataPagamento`,`boleto`.`valor` AS `valor`,`boleto`.`fkFornecedor` AS `fkFornecedor` from `boleto` where ((`boleto`.`pago` = 0) and (`boleto`.`dataVencimento` between curdate() and (curdate() + interval 7 day))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kpi_contas_atrasadas`
--

/*!50001 DROP VIEW IF EXISTS `vw_kpi_contas_atrasadas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kpi_contas_atrasadas` AS select count(0) AS `QtdAtrasadas` from `boleto` where ((`boleto`.`pago` = 0) and (`boleto`.`dataVencimento` < curdate())) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kpi_estoque_baixo`
--

/*!50001 DROP VIEW IF EXISTS `vw_kpi_estoque_baixo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kpi_estoque_baixo` AS select `i`.`nome` AS `Insumo`,sum(`l`.`quantidadeAtual`) AS `EstoqueTotal`,`i`.`qtdMinima` AS `qtdMinima` from ((`insumo` `i` left join `marca` `m` on((`i`.`idInsumo` = `m`.`fkInsumo`))) left join `lote` `l` on((`m`.`idMarca` = `l`.`fkMarca`))) where (`i`.`ativo` = 1) group by `i`.`idInsumo`,`i`.`nome`,`i`.`qtdMinima` having ((`EstoqueTotal` <= `i`.`qtdMinima`) or (`EstoqueTotal` is null)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kpi_validade_proxima`
--

/*!50001 DROP VIEW IF EXISTS `vw_kpi_validade_proxima`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kpi_validade_proxima` AS select `i`.`nome` AS `Insumo`,`l`.`dataValidade` AS `dataValidade`,`l`.`quantidadeAtual` AS `QtdAtual`,(to_days(`l`.`dataValidade`) - to_days(curdate())) AS `DiasParaVencer` from ((`lote` `l` join `marca` `m` on((`l`.`fkMarca` = `m`.`idMarca`))) join `insumo` `i` on((`m`.`fkInsumo` = `i`.`idInsumo`))) where ((`l`.`dataValidade` <= (curdate() + interval 7 day)) and (`i`.`ativo` = 1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_pedido_aberto_mais_antigo`
--

/*!50001 DROP VIEW IF EXISTS `vw_pedido_aberto_mais_antigo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_pedido_aberto_mais_antigo` AS select `c`.`nome` AS `Cliente`,`d`.`dataCompra` AS `dataCompra`,`d`.`valor` AS `valor`,`d`.`pedido` AS `pedido`,(to_days(curdate()) - to_days(`d`.`dataCompra`)) AS `DiasEmAberto` from (`divida` `d` join `cliente` `c` on((`d`.`fkCliente` = `c`.`idCliente`))) where (`d`.`pago` = 0) order by `d`.`dataCompra` limit 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_predicao_falta_estoque`
--

/*!50001 DROP VIEW IF EXISTS `vw_predicao_falta_estoque`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_predicao_falta_estoque` AS select `i`.`nome` AS `Insumo`,sum(`l`.`quantidadeAtual`) AS `EstoqueAtual`,`i`.`qtdMinima` AS `qtdMinima`,(sum(`l`.`quantidadeAtual`) - `i`.`qtdMinima`) AS `MargemSeguranca` from ((`insumo` `i` join `marca` `m` on((`i`.`idInsumo` = `m`.`fkInsumo`))) join `lote` `l` on((`m`.`idMarca` = `l`.`fkMarca`))) group by `i`.`idInsumo`,`i`.`nome`,`i`.`qtdMinima` having (`EstoqueAtual` > 0) order by `MargemSeguranca` limit 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_predicao_perda_validade`
--

/*!50001 DROP VIEW IF EXISTS `vw_predicao_perda_validade`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_predicao_perda_validade` AS select `i`.`nome` AS `Insumo`,`l`.`quantidadeAtual` AS `QtdNoLote`,`l`.`dataValidade` AS `dataValidade`,(to_days(`l`.`dataValidade`) - to_days(curdate())) AS `DiasRestantes` from ((`lote` `l` join `marca` `m` on((`l`.`fkMarca` = `m`.`idMarca`))) join `insumo` `i` on((`m`.`fkInsumo` = `i`.`idInsumo`))) where ((`l`.`dataValidade` > curdate()) and ((to_days(`l`.`dataValidade`) - to_days(curdate())) <= 5)) order by `l`.`quantidadeAtual` desc limit 1 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_total_contas_semana`
--

/*!50001 DROP VIEW IF EXISTS `vw_total_contas_semana`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_total_contas_semana` AS select coalesce(sum(`boleto`.`valor`),0) AS `ValorTotalSemana` from `boleto` where (yearweek(`boleto`.`dataVencimento`,1) = yearweek(curdate(),1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_total_divida_clientes`
--

/*!50001 DROP VIEW IF EXISTS `vw_total_divida_clientes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_total_divida_clientes` AS select coalesce(sum(`divida`.`valor`),0) AS `TotalReceber` from `divida` where (`divida`.`pago` = 0) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_total_entrada_estoque_semana`
--

/*!50001 DROP VIEW IF EXISTS `vw_total_entrada_estoque_semana`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_total_entrada_estoque_semana` AS select coalesce(sum((`l`.`precoUnit` * `l`.`quantidadeAtual`)),0) AS `ValorTotalEntradas` from `lote` `l` where (yearweek(`l`.`dataEntrada`,1) = yearweek(curdate(),1)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_total_perda_validade`
--

/*!50001 DROP VIEW IF EXISTS `vw_total_perda_validade`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_total_perda_validade` AS select coalesce(sum((`l`.`precoUnit` * `l`.`quantidadeAtual`)),0) AS `ValorTotalPerda` from `lote` `l` where ((`l`.`dataValidade` < curdate()) and (`l`.`quantidadeAtual` > 0)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_total_valor_atrasado`
--

/*!50001 DROP VIEW IF EXISTS `vw_total_valor_atrasado`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_total_valor_atrasado` AS select coalesce(sum(`boleto`.`valor`),0) AS `TotalDividaFornecedor` from `boleto` where ((`boleto`.`pago` = 0) and (`boleto`.`dataVencimento` < curdate())) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-09 22:44:43
