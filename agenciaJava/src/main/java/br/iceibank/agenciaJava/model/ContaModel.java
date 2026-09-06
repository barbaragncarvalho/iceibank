package br.iceibank.agenciaJava.model;

public class ContaModel {
    private int id;
    private String nomeAluno;
    private double saldoInicial;

    public ContaModel() {}
    public ContaModel(int id, String nomeAluno, double saldoInicial) {
        this.id = id;
        this.nomeAluno = nomeAluno;
        this.saldoInicial = saldoInicial;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getNomeAluno() { return nomeAluno; }
    public void setNomeAluno(String nomeAluno) { this.nomeAluno = nomeAluno; }
    public double getSaldoInicial() { return saldoInicial; }
    public void setSaldoInicial(double saldoInicial) { this.saldoInicial = saldoInicial; }
}