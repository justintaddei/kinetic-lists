export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  private: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_member: { Args: { p_household_id: string }; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      arrivals: {
        Row: {
          arrived_at: string
          household_id: string
          id: string
          location_id: string
          user_id: string
        }
        Insert: {
          arrived_at?: string
          household_id: string
          id?: string
          location_id: string
          user_id: string
        }
        Update: {
          arrived_at?: string
          household_id?: string
          id?: string
          location_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "arrivals_household_id_location_id_fkey"
            columns: ["household_id", "location_id"]
            isOneToOne: false
            referencedRelation: "store_locations"
            referencedColumns: ["household_id", "id"]
          },
        ]
      }
      household_invites: {
        Row: {
          created_at: string
          created_by: string
          expires_at: string
          household_id: string
          joined_at: string | null
          joined_by: string | null
          token: string
        }
        Insert: {
          created_at?: string
          created_by: string
          expires_at?: string
          household_id: string
          joined_at?: string | null
          joined_by?: string | null
          token?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          expires_at?: string
          household_id?: string
          joined_at?: string | null
          joined_by?: string | null
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "household_invites_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      household_members: {
        Row: {
          display_name: string
          household_id: string
          user_id: string
        }
        Insert: {
          display_name: string
          household_id: string
          user_id: string
        }
        Update: {
          display_name?: string
          household_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "household_members_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      households: {
        Row: {
          id: string
          name: string
        }
        Insert: {
          id?: string
          name?: string
        }
        Update: {
          id?: string
          name?: string
        }
        Relationships: []
      }
      item_store_tags: {
        Row: {
          created_at: string
          created_by: string
          item_id: string
          store_id: string
        }
        Insert: {
          created_at?: string
          created_by: string
          item_id: string
          store_id: string
        }
        Update: {
          created_at?: string
          created_by?: string
          item_id?: string
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "item_store_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "item_store_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "roster_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "item_store_tags_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "roster_stores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "item_store_tags_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      items: {
        Row: {
          category: string | null
          household_id: string
          id: string
          name: string
          quantity: string | null
        }
        Insert: {
          category?: string | null
          household_id: string
          id?: string
          name: string
          quantity?: string | null
        }
        Update: {
          category?: string | null
          household_id?: string
          id?: string
          name?: string
          quantity?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "items_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      list_items: {
        Row: {
          household_id: string
          id: string
          item_id: string
          list_id: string
          status: string
          stocked_at: string | null
        }
        Insert: {
          household_id: string
          id?: string
          item_id: string
          list_id: string
          status?: string
          stocked_at?: string | null
        }
        Update: {
          household_id?: string
          id?: string
          item_id?: string
          list_id?: string
          status?: string
          stocked_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "list_items_item_id_household_id_fkey"
            columns: ["household_id", "item_id"]
            isOneToOne: false
            referencedRelation: "items"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "list_items_item_id_household_id_fkey"
            columns: ["household_id", "item_id"]
            isOneToOne: false
            referencedRelation: "roster_items"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "list_items_list_id_household_id_fkey"
            columns: ["household_id", "list_id"]
            isOneToOne: false
            referencedRelation: "lists"
            referencedColumns: ["household_id", "id"]
          },
        ]
      }
      lists: {
        Row: {
          household_id: string
          id: string
          name: string
        }
        Insert: {
          household_id: string
          id?: string
          name: string
        }
        Update: {
          household_id?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "lists_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_lines: {
        Row: {
          household_id: string
          id: string
          item_id: string
          list_item_id: string
          purchase_id: string
          store_id: string
        }
        Insert: {
          household_id: string
          id?: string
          item_id: string
          list_item_id: string
          purchase_id: string
          store_id: string
        }
        Update: {
          household_id?: string
          id?: string
          item_id?: string
          list_item_id?: string
          purchase_id?: string
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchase_lines_household_id_item_id_fkey"
            columns: ["household_id", "item_id"]
            isOneToOne: false
            referencedRelation: "items"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "purchase_lines_household_id_item_id_fkey"
            columns: ["household_id", "item_id"]
            isOneToOne: false
            referencedRelation: "roster_items"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "purchase_lines_household_id_list_item_id_fkey"
            columns: ["household_id", "list_item_id"]
            isOneToOne: false
            referencedRelation: "list_items"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "purchase_lines_purchase_id_store_id_fkey"
            columns: ["purchase_id", "store_id"]
            isOneToOne: false
            referencedRelation: "purchases"
            referencedColumns: ["id", "store_id"]
          },
        ]
      }
      purchases: {
        Row: {
          bought_at: string
          bought_by: string
          household_id: string
          id: string
          location_id: string | null
          session_token: string
          sold_at: string
          store_id: string
        }
        Insert: {
          bought_at: string
          bought_by: string
          household_id: string
          id?: string
          location_id?: string | null
          session_token: string
          sold_at: string
          store_id: string
        }
        Update: {
          bought_at?: string
          bought_by?: string
          household_id?: string
          id?: string
          location_id?: string | null
          session_token?: string
          sold_at?: string
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "purchases_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "purchases_household_id_location_id_fkey"
            columns: ["household_id", "location_id"]
            isOneToOne: false
            referencedRelation: "store_locations"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "purchases_household_id_store_id_fkey"
            columns: ["household_id", "store_id"]
            isOneToOne: false
            referencedRelation: "roster_stores"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "purchases_household_id_store_id_fkey"
            columns: ["household_id", "store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["household_id", "id"]
          },
        ]
      }
      store_locations: {
        Row: {
          geofence_m: number
          household_id: string
          id: string
          lat: number
          lng: number
          store_id: string
        }
        Insert: {
          geofence_m?: number
          household_id: string
          id?: string
          lat: number
          lng: number
          store_id: string
        }
        Update: {
          geofence_m?: number
          household_id?: string
          id?: string
          lat?: number
          lng?: number
          store_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "store_locations_store_id_household_id_fkey"
            columns: ["store_id", "household_id"]
            isOneToOne: false
            referencedRelation: "roster_stores"
            referencedColumns: ["household_id", "id"]
          },
          {
            foreignKeyName: "store_locations_store_id_household_id_fkey"
            columns: ["store_id", "household_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["household_id", "id"]
          },
        ]
      }
      stores: {
        Row: {
          household_id: string
          id: string
          name: string
        }
        Insert: {
          household_id: string
          id?: string
          name: string
        }
        Update: {
          household_id?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "stores_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      roster_items: {
        Row: {
          category: string | null
          household_id: string | null
          id: string | null
          list_count: number | null
          name: string | null
          quantity: string | null
          store_names: string[] | null
        }
        Insert: {
          category?: string | null
          household_id?: string | null
          id?: string | null
          list_count?: never
          name?: string | null
          quantity?: string | null
          store_names?: never
        }
        Update: {
          category?: string | null
          household_id?: string | null
          id?: string | null
          list_count?: never
          name?: string | null
          quantity?: string | null
          store_names?: never
        }
        Relationships: [
          {
            foreignKeyName: "items_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
      roster_stores: {
        Row: {
          household_id: string | null
          id: string | null
          location_count: number | null
          name: string | null
          tag_count: number | null
        }
        Insert: {
          household_id?: string | null
          id?: string | null
          location_count?: never
          name?: string | null
          tag_count?: never
        }
        Update: {
          household_id?: string | null
          id?: string | null
          location_count?: never
          name?: string | null
          tag_count?: never
        }
        Relationships: [
          {
            foreignKeyName: "stores_household_id_fkey"
            columns: ["household_id"]
            isOneToOne: false
            referencedRelation: "households"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      buy_basket: {
        Args: {
          p_location_id: string
          p_session_token: string
          p_sold_at: string
          p_store_id: string
        }
        Returns: Json
      }
      join_household: { Args: { p_token: string }; Returns: Json }
      preview_invitation: { Args: { p_token: string }; Returns: Json }
      uuidv7: { Args: never; Returns: string }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  private: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
