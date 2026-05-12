import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/personne.dart';
import '../models/date_partielle.dart';

class ModernPersonCard extends StatelessWidget {
  final Personne personne;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ModernPersonCard({
    super.key,
    required this.personne,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar ou icône
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: personne.photoPath != null && personne.photoPath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            personne.photoPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(context);
                            },
                          ),
                        )
                      : _buildDefaultAvatar(context),
                ),
                const SizedBox(width: 16),
                
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom complet
                      Text(
                        personne.nomComplet,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                          letterSpacing: -0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Informations secondaires
                      Row(
                        children: [
                          if (personne.dateNaissance != null) ...[
                            Icon(
                              Icons.cake,
                              size: 14,
                              color: const Color(0xFF757575),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDatePartielle(personne.dateNaissance!),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                          if (personne.lieuNaissance != null && personne.lieuNaissance!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: const Color(0xFF757575),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              personne.lieuNaissance!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF757575),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Statut ou badge
                      if (personne.dateDeces != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Décédé(e)',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions
                if (showActions) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: const Color(0xFF757575),
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: const Color(0xFF212121),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Modifier',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Supprimer',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    final initials = _getInitials(personne.nomComplet);
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }

  String _formatDatePartielle(DatePartielle date) {
    final now = DateTime.now();
    int age = now.year - date.annee;
    
    // Ajuster l'âge si l'anniversaire n'est pas encore passé cette année
    if (date.mois != null && date.mois! > now.month) {
      age--;
    } else if (date.mois == now.month && date.jour != null && date.jour! > now.day) {
      age--;
    }
    
    if (age < 0) {
      return 'À naître';
    } else if (age == 0) {
      return 'Moins d\'un an';
    } else if (age == 1) {
      return '1 an';
    } else {
      return '$age ans';
    }
  }
}
