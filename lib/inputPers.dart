
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';


InputDecoration darkInput(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color.fromARGB(97, 147, 145, 145)),
    filled: true,
    fillColor: const Color.fromARGB(255, 255, 255, 255),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white),
    ),
  );
}