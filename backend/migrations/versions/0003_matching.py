"""matching: match records and dealer sourcing makes

Additive only. dealer.sourcing_makes_csv is NOT NULL with a server default so existing
dealers get an empty list.

Revision ID: 0003
Revises: 0002
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0003'
down_revision: Union[str, Sequence[str], None] = '0002'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('dealer') as batch:
        batch.add_column(
            sa.Column('sourcing_makes_csv', sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default='')
        )
    op.create_table(
        'matchrecord',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('requirement_id', sa.Uuid(), nullable=False),
        sa.Column('dealer_id', sa.Uuid(), nullable=False),
        sa.Column('vehicle_id', sa.Uuid(), nullable=True),
        sa.Column('tier', sa.Integer(), nullable=False),
        sa.Column('score', sa.Integer(), nullable=False),
        sa.Column('reasons_csv', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('dismissed_at', sa.DateTime(), nullable=True),
        sa.Column('dismissed_reason', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['requirement_id'], ['buyrequirement.id']),
        sa.ForeignKeyConstraint(['dealer_id'], ['dealer.id']),
        sa.ForeignKeyConstraint(['vehicle_id'], ['vehicle.id']),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('requirement_id', 'dealer_id', name='uq_match_requirement_dealer'),
    )
    op.create_index(op.f('ix_matchrecord_requirement_id'), 'matchrecord', ['requirement_id'])
    op.create_index(op.f('ix_matchrecord_dealer_id'), 'matchrecord', ['dealer_id'])
    op.create_index(op.f('ix_matchrecord_created_at'), 'matchrecord', ['created_at'])


def downgrade() -> None:
    op.drop_table('matchrecord')
    with op.batch_alter_table('dealer') as batch:
        batch.drop_column('sourcing_makes_csv')
