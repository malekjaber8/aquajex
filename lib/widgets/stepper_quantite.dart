import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/commande.dart';

/// Sélecteur de quantité : boutons +/- comme avant, mais le nombre au
/// centre est aussi un champ éditable au clavier. Accepte les quantités
/// fractionnaires (ex. 0.4, 1.25), certains articles ne se vendant pas à
/// l'unité entière.
class StepperQuantite extends StatefulWidget {
  final double quantite;
  final List<Color> accent;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  final ValueChanged<double> onChanged;

  const StepperQuantite({
    super.key,
    required this.quantite,
    required this.accent,
    required this.onMoins,
    required this.onPlus,
    required this.onChanged,
  });

  @override
  State<StepperQuantite> createState() => _StepperQuantiteState();
}

class _StepperQuantiteState extends State<StepperQuantite> {
  late final TextEditingController _ctrl = TextEditingController(
    text: formatQuantite(widget.quantite),
  );

  @override
  void didUpdateWidget(covariant StepperQuantite oldWidget) {
    super.didUpdateWidget(oldWidget);
    final texte = formatQuantite(widget.quantite);
    if (oldWidget.quantite != widget.quantite && _ctrl.text != texte) {
      _ctrl.value = _ctrl.value.copyWith(
        text: texte,
        selection: TextSelection.collapsed(offset: texte.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _valider(String valeur) {
    final n = double.tryParse(valeur.trim().replaceAll(',', '.'));
    if (n == null) {
      _ctrl.text = formatQuantite(widget.quantite);
      return;
    }
    widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _boutonStepper(Icons.remove, widget.onMoins),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3B5F),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
              ),
              onSubmitted: _valider,
              onTapOutside: (_) => _valider(_ctrl.text),
            ),
          ),
          _boutonStepper(Icons.add, widget.onPlus),
        ],
      ),
    );
  }

  Widget _boutonStepper(IconData icon, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: const Color(0xFF1B3B5F)),
      ),
    );
  }
}
