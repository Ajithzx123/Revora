"""sell side: richer listings, sell matching, offer lifecycle and revisions, dealer buy makes

Additive. New NOT NULL columns carry server defaults so existing rows stay valid.

Revision ID: 0007
Revises: 0006
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel


revision: str = '0007'
down_revision: Union[str, Sequence[str], None] = '0006'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('dealer') as batch:
        batch.add_column(sa.Column('buy_makes_csv', sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=''))
    with op.batch_alter_table('selllisting') as batch:
        batch.add_column(sa.Column('status_reason', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('variant', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('owners', sa.Integer(), nullable=False, server_default='1'))
        batch.add_column(sa.Column('color', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('urgency', sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default='NORMAL'))
        batch.add_column(sa.Column('loan_outstanding', sa.Boolean(), nullable=False, server_default=sa.false()))
        batch.add_column(sa.Column('loan_amount', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('challans_amount', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('insurance_valid', sa.Boolean(), nullable=True))
        batch.add_column(sa.Column('description', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('expires_at', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('updated_at', sa.DateTime(), nullable=True))
    with op.batch_alter_table('dealeroffer') as batch:
        batch.add_column(sa.Column('status_reason', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('void_cause', sqlmodel.sql.sqltypes.AutoString(), nullable=True))
        batch.add_column(sa.Column('revision', sa.Integer(), nullable=False, server_default='1'))
        batch.add_column(sa.Column('valid_until', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('inspection_required', sa.Boolean(), nullable=False, server_default=sa.true()))
        batch.add_column(sa.Column('pickup_days', sa.Integer(), nullable=True))
        batch.add_column(sa.Column('accepted_at', sa.DateTime(), nullable=True))
        batch.add_column(sa.Column('updated_at', sa.DateTime(), nullable=True))
    op.create_table(
        'sellmatch',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('listing_id', sa.Uuid(), nullable=False),
        sa.Column('dealer_id', sa.Uuid(), nullable=False),
        sa.Column('score', sa.Integer(), nullable=False),
        sa.Column('reasons_csv', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('dismissed_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['dealer_id'], ['dealer.id']),
        sa.ForeignKeyConstraint(['listing_id'], ['selllisting.id']),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('listing_id', 'dealer_id', name='uq_sellmatch_listing_dealer'),
    )
    op.create_index(op.f('ix_sellmatch_listing_id'), 'sellmatch', ['listing_id'])
    op.create_index(op.f('ix_sellmatch_dealer_id'), 'sellmatch', ['dealer_id'])
    op.create_table(
        'offerrevision',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('offer_id', sa.Uuid(), nullable=False),
        sa.Column('revision', sa.Integer(), nullable=False),
        sa.Column('price', sa.Integer(), nullable=False),
        sa.Column('message', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['offer_id'], ['dealeroffer.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_offerrevision_offer_id'), 'offerrevision', ['offer_id'])


def downgrade() -> None:
    op.drop_table('offerrevision')
    op.drop_table('sellmatch')
    with op.batch_alter_table('dealeroffer') as batch:
        for c in ('updated_at', 'accepted_at', 'pickup_days', 'inspection_required', 'valid_until', 'revision', 'void_cause', 'status_reason'):
            batch.drop_column(c)
    with op.batch_alter_table('selllisting') as batch:
        for c in ('updated_at', 'expires_at', 'description', 'insurance_valid', 'challans_amount', 'loan_amount',
                  'loan_outstanding', 'urgency', 'color', 'owners', 'variant', 'status_reason'):
            batch.drop_column(c)
    with op.batch_alter_table('dealer') as batch:
        batch.drop_column('buy_makes_csv')
