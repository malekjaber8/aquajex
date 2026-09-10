import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sélecteur de quantité : boutons +/- comme avant, mais le nombre au
/// centre est aussi un champ éditable au clavier.
class StepperQuantite extends StatefulWidget {
  final int quantite;
  final List<Color> accent;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  final ValueChanged<int> onChanged;

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
    text: '${widget.quantite}',
  );

  @override
  void didUpdateWidget(covariant StepperQuantite oldWidget) {
    super.didUpdateWidget(oldWidget);
    final texte = '${widget.quantite}';
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
    final n = int.tryParse(valeur.trim());
    if (n == null) {
      _ctrl.text = '${widget.quantite}';
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
            width: 32,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
