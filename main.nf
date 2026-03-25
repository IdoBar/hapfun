#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { HAPFUN } from './workflows/hapfun'
workflow { HAPFUN() }
