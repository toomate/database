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