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
WHERE l.dataValidade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY);


-- 2. KPI: Itens com estoque abaixo ou igual ao minimo
CREATE VIEW vw_kpi_estoque_baixo AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeAtual) AS EstoqueTotal,
    i.qtdMinima
FROM insumo i
LEFT JOIN marca m ON i.idInsumo = m.fkInsumo
LEFT JOIN lote l ON m.idMarca = l.fkMarca
GROUP BY i.idInsumo, i.nome, i.qtdMinima
HAVING EstoqueTotal <= i.qtdMinima OR EstoqueTotal IS NULL;


-- 3. KPI: Contas (Boletos) jA vencidas
CREATE VIEW vw_kpi_contas_atrasadas AS
SELECT count(*) as QtdAtrasadas
FROM boleto
WHERE pago = 0 AND dataVencimento < CURDATE();


-- 4. GrAfico: Estoque Atual vs Minimo (Para visualizaçao)
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
GROUP BY i.idInsumo, i.nome, i.qtdMinima;


-- 5. KPI: Boletos vencendo nos prOximos 7 dias
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
WHERE l.dataValidade < CURDATE();




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



-- ================================================================
-- Script de geração de dados mock históricos - SQL puro
-- Simula estoque de restaurante com alta rotatividade (PF + Feijoada)
-- ================================================================

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