package br.iceibank.agenciaJava.services;

import org.springframework.stereotype.Service;

@Service
public class CompararVetoresService {

    public String comparar(int[] a, int[] b) {
        if (a == null || b == null || a.length != b.length) {
            return "CONCORRENTES";
        }
        boolean aMenorEmAlgum = false;
        boolean bMenorEmAlgum = false;

        for (int i = 0; i < a.length; i++) {
            if (a[i] < b[i])
                aMenorEmAlgum = true;
            if (b[i] < a[i])
                bMenorEmAlgum = true;
        }

        if (!aMenorEmAlgum && !bMenorEmAlgum)
            return "IGUAIS";
        if (aMenorEmAlgum && !bMenorEmAlgum)
            return "ANTES";
        if (bMenorEmAlgum && !aMenorEmAlgum)
            return "DEPOIS";
        return "CONCORRENTES";
    }
}