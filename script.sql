CREATE DATABASE toomate;
USE toomate;
CREATE TABLE usuario (
    idUsuario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    senha CHAR(64),
    administrador TINYINT,
    apelido VARCHAR(45)
);

CREATE TABLE categoria (
    idCategoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    rotatividade TINYINT
);

CREATE TABLE insumo (
    idInsumo INT PRIMARY KEY AUTO_INCREMENT,
    fkCategoria INT,
    nome VARCHAR(45),
    qtdMinima INT,
    unidadeMedida VARCHAR(20),
    CONSTRAINT fk_insumo_categoria FOREIGN KEY (fkCategoria) REFERENCES categoria(idCategoria)
);

CREATE TABLE rotina (
    idRotina INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(45),
    quantidadeMedida INT
);

CREATE TABLE rotinaInsumo (
    idRotina INT,
    idInsumo INT,
    PRIMARY KEY (idRotina, idInsumo),
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
    quantidadeMedida DOUBLE,
    dateEntrada DATE,
    fkIngrediente INT,
    fkUsuario INT,
    CONSTRAINT fk_lote_insumo FOREIGN KEY (fkIngrediente) REFERENCES insumo(idInsumo),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (fkUsuario) REFERENCES usuario(idUsuario)
);

CREATE TABLE arquivo (
    idArquivo INT PRIMARY KEY AUTO_INCREMENT,
    nomeOriginal VARCHAR(45),
    chave VARCHAR(45),
    nomeBucket VARCHAR(45),
    dtCriacao DATETIME,
    dtAlteracao DATETIME
);

CREATE TABLE arquivo_relacionamento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fk_arquivo INT,
    tipo_entidade VARCHAR(45),
    id_entidade INT,
	CONSTRAINT fk_arq_rel_arquivo FOREIGN KEY (fk_arquivo) REFERENCES arquivo(idArquivo)
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
    valor DECIMAL(6,2),
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
    valor DECIMAL(6,2),
    fkFornecedor INT,
    CONSTRAINT fk_boleto_fornecedor FOREIGN KEY (fkFornecedor) REFERENCES fornecedor(idFornecedor)
);
