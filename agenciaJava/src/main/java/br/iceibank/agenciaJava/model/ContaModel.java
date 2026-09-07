package br.iceibank.agenciaJava.model;

public class ContaModel {
    private int id;
    private String nomeAluno;
    private double saldoInicial;
    private String senha;

    public ContaModel() {}
    public ContaModel(int id, String nomeAluno, double saldoInicial, String senha) {
        this.id = id;
        this.nomeAluno = nomeAluno;
        this.saldoInicial = saldoInicial;
        this.senha = senha;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getNomeAluno() { return nomeAluno; }
    public void setNomeAluno(String nomeAluno) { this.nomeAluno = nomeAluno; }
    public double getSaldoInicial() { return saldoInicial; }
    public void setSaldoInicial(double saldoInicial) { this.saldoInicial = saldoInicial; }
    public String getSenha() { return senha; }
    public void setSenha(String senha) { this.senha = senha; }
}