"""sell side: seller/dealer counter-offers and the inspection final offer

Additive. The new NOT NULL column carries a server default so existing rows stay valid.

Revision ID: 0008
Revises: 0007
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0008'
down_revision: Union[str, Sequence[str], None] = '0007'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('dealeroffer') as batch:
        batch.add_column(sa.Column('final_status', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('final_price', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('final_reason_code', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('final_reason_note', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('final_evidence_csv', sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=''))
        batch.add_column(sa.Column('final_submitted_at', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('final_decided_at', sa.DateTime(), nullable=True))
    op.create_table(
        'offerround',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('offer_id', sa.Uuid(), nullable=False),
        sa.Column('round_no', sa.Integer(), nullable=False),
        sa.Column('by', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('note', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('status', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('valid_until', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['offer_id'], ['dealeroffer.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_offerround_offer_id'), 'offerround', ['offer_id'])


def downgrade() -> None:
    op.drop_table('offerround')
    with op.batch_alter_table('dealeroffer') as batch:
        for c in ('final_decided_at', 'final_submitted_at', 'final_evidence_csv', 'final_reason_note',
                  'final_reason_code', 'final_price', 'final_status'):
            batch.drop_column(c)
